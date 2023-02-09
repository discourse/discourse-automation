# frozen_string_literal: true
include HasSanitizableFields

DiscourseAutomation::Scriptable::SCHEDULED_EXPLORER_QUERY = 'scheduled_explorer_query'

DiscourseAutomation::Scriptable.add(DiscourseAutomation::Scriptable::SCHEDULED_EXPLORER_QUERY) do
  queries = SiteSetting.data_explorer_enabled ? DataExplorer::Query.where(hidden: false).map { |q| { id: q.id, translated_name: q.name } } : []
  field :recipients, component: :email_group_user, required: true
  field :query_id, component: :choices, required: true, extra: { content: queries }
  field :query_params, component: :'key-value', accepts_placeholders: true

  version 1
  triggerables [:recurring]

  script do |context, fields, automation|
    recipients = Array(fields.dig('recipients', 'value'))
    query_id = fields.dig('query_id', 'value')
    query_params = JSON.parse(fields.dig('query_params', 'value'))
    creator = User.find_by(id: automation.last_updated_by_id)
    usernames = []

    unless SiteSetting.data_explorer_enabled
      Rails.logger.warn '[discourse-automation] Report requires Data Explorer plugin to be enabled'
      next
    end

    unless recipients.present?
      Rails.logger.warn "[discourse-automation] Couldn't find any recipients"
      next
    end

    query = DataExplorer::Query.find(query_id)
    query.update!(last_run_at: Time.now)

    # ensure groups and users have access to query
    recipients.each do |recipient|
      if recipient.include?("@") && creator.present?
        usernames << recipient if Guardian.new(creator).can_send_private_messages_to_email?
      elsif group = Group.find_by(name: recipient)
        group.users.each do |user|
          usernames << user.username if Guardian.new(user).group_and_user_can_access_query?(group, query)
        end
      elsif user = User.find_by(username: recipient)
        usernames << user.username if Guardian.new(user).user_can_access_query?(query)
      end
    end

    params = {}
    unless query_params.blank?
      k, v = [], []
      query_params.flatten.each.with_index { |p, i| i % 2 == 0 ? k << p : v << p }
      params = Hash[ k.zip(v) ]
    end

    result = DataExplorer.run_query(query, params)
    pg_result = result[:pg_result]
    relations, colrender = DataExplorer.add_extra_data(pg_result)
    result_data = []

    # column names to search in place of id columns (topic_id, user_id etc)
    cols = ["name", "title", "username"]

    # find values from extra data, based on result id
    pg_result.values.each do |row|
      row_data = []

      row.each_with_index do |col, col_index|
        col_name = pg_result.fields[col_index]
        related = relations.dig(colrender[col_index].to_sym) if col_index < colrender.size

        if related.is_a?(ActiveModel::ArraySerializer)
          related_row = related.object.find_by(id: col)
          column = !col_name.include?("_id") ? related_row.try(col_name) : cols.find { |c| related_row.try c }
          row_data[col_index] = column.nil? ? col : related_row[column]
        else
          row_data[col_index] = col
        end
      end

      result_data << row_data.map { |c| "<td>#{ sanitize_field(c.to_s) }</td>" }.join
    end

    # present query results in table format
    cols = pg_result.fields.map { |c| "<th>#{c.gsub('_id', '')}</th>" }.join
    rows = result_data.map { |row| "<tr>#{row}</tr>" }.join
    table = "<table><thead><tr>#{cols}</tr></thead><tbody>#{rows}</tbody></table>"

    # send private message with data explorer results to each user in group
    usernames.flatten.compact.uniq.each do |username|
      title = "Scheduled Report for #{query.name}"
      message = "Hi #{username}, your data explorer report is ready.\n\n" +
      "Query Name:\n#{query.name}\n\nHere are the results:\n#{table.html_safe}\n\n" +
      "<a href='/admin/plugins/explorer?id=#{query_id}'>View this query in Data Explorer</a>\n\n" +
      "Report created at #{Time.zone.now.strftime("%Y-%m-%d at %H:%M:%S")} (#{Time.zone.name})"

      utils.send_pm({ title: title, raw: message, target_usernames: Array(username) }, automation_id: automation.id)
    end
  end
end
