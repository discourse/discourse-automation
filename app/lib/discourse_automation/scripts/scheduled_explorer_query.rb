# frozen_string_literal: true
include HasSanitizableFields

DiscourseAutomation::Scriptable::SCHEDULED_EXPLORER_QUERY = "scheduled_explorer_query"

DiscourseAutomation::Scriptable.add(DiscourseAutomation::Scriptable::SCHEDULED_EXPLORER_QUERY) do
  queries = []
  if SiteSetting.data_explorer_enabled
    queries =
      DataExplorer::Query.where(hidden: false).map { |q| { id: q.id, translated_name: q.name } }
  end

  field :recipients, component: :email_group_user, required: true
  field :query_id, component: :choices, required: true, extra: { content: queries }
  field :query_params, component: :"key-value", accepts_placeholders: true

  version 1
  triggerables [:recurring]

  script do |context, fields, automation|
    recipients = Array(fields.dig("recipients", "value"))
    query_id = fields.dig("query_id", "value")
    query_params = JSON.parse(fields.dig("query_params", "value"))
    creator = User.find_by(id: automation.last_updated_by_id)
    usernames = []

    unless SiteSetting.data_explorer_enabled
      Rails.logger.warn "[discourse-automation] Data Explorer plugin must be enabled"
      next
    end

    unless recipients.present?
      Rails.logger.warn "[discourse-automation] Couldn't find any recipients"
      next
    end

    query = DataExplorer::Query.find(query_id)
    query.update!(last_run_at: Time.now)

    puts "Query: #{query.name}"

    # ensure groups and users have access to query
    recipients.each do |recipient|
      if recipient.include?("@") && creator.present?
        usernames << recipient if Guardian.new(creator).can_send_private_messages_to_email?
      elsif group = Group.find_by(name: recipient)
        group.users.each do |user|
          if Guardian.new(user).group_and_user_can_access_query?(group, query)
            usernames << user.username
          end
        end
      elsif user = User.find_by(username: recipient)
        usernames << user.username if Guardian.new(user).user_can_access_query?(query)
      end
    end

    params = {}
    unless query_params.blank?
      k, v = [], []
      query_params.flatten.each.with_index do |p, i|
        if i % 2 == 0
          k << p
        else
          v << p
        end
      end

      params = Hash[k.zip(v)]
    end

    result = DataExplorer.run_query(query, params)
    pg_result = result[:pg_result]
    relations, colrender = DataExplorer.add_extra_data(pg_result)
    result_data = []

    # column names to search in place of id columns (topic_id, user_id etc)
    cols = %w[name title username]

    # find values from extra data, based on result id
    pg_result.values.each do |row|
      row_data = []

      row.each_with_index do |col, col_index|
        col_name = pg_result.fields[col_index]
        related = relations.dig(colrender[col_index].to_sym) if col_index < colrender.size

        if related.is_a?(ActiveModel::ArraySerializer)
          related_row = related.object.find_by(id: col)
          if col_name.include?("_id")
            column = cols.find { |c| related_row.try c }
          else
            column = related_row.try(col_name)
          end

          if column.nil?
            row_data[col_index] = col
          else
            row_data[col_index] = related_row[column]
          end
        else
          row_data[col_index] = col
        end
      end

      result_data << row_data.map { |c| "| #{sanitize_field(c.to_s)} " }.join + "|\n"
    end

    # present query results in table format
    table_headers = "|" + pg_result.fields.map { |c| " #{c.gsub("_id", "")} |" }.join
    table_body = "|" + pg_result.fields.size.times.map { " :-----: |" }.join
    table = table_headers + "\n" + table_body + "\n" + result_data.join

    # send private message with data explorer results to each user in group
    usernames.flatten.compact.uniq.each do |username|
      pm = {}
      pm["title"] = "Scheduled Report for #{query.name}"
      pm["target_usernames"] = Array(username)
      pm["raw"] = "Hi #{username}, your data explorer report is ready.\n\n" +
        "Query Name:\n#{query.name}\n\nHere are the results:\n#{table}\n\n" +
        "<a href='/admin/plugins/explorer?id=#{query_id}'>View query in Data Explorer</a>\n\n" +
        "Report created at #{Time.zone.now.strftime("%Y-%m-%d at %H:%M:%S")} (#{Time.zone.name})"

      utils.send_pm(pm, automation_id: automation.id)
    end
  end
end
