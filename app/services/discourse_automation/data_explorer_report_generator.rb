class DataExplorerReportGenerator
  def initialize(automation)
    @automation = automation
  end

  def generate(query_id, query_params, recipients)
    query = DataExplorer::Query.find(query_id)
    query.update!(last_run_at: Time.now)

    usernames = filter_recipients_by_query_access(recipients, query)

    params = params_to_hash(query_params)
    result = DataExplorer.run_query(query, params)

    table = markdown_table_data(result[:pg_result])

    build_report_pms(query, table, usernames)
  end

  def filter_recipients_by_query_access(recipients, query)
    creator = User.find_by(id: @automation.last_updated_by_id)
    names = []

    recipients.each do |recipient|
      if recipient.include?("@") && creator.present?
        names << recipient if Guardian.new(creator).can_send_private_messages_to_email?
      elsif group = Group.find_by(name: recipient)
        group.users.each do |user|
          if Guardian.new(user).group_and_user_can_access_query?(group, query)
            names << user.username
          end
        end
      elsif user = User.find_by(username: recipient)
        names << user.username if Guardian.new(user).user_can_access_query?(query)
      end
    end
    names
  end

  def params_to_hash(query_params)
    params = JSON.parse(query_params)
    params_hash = {}

    if !params.blank?
      param_key, param_value = [], []
      params.flatten.each.with_index do |data, i|
        if i % 2 == 0
          param_key << data
        else
          param_value << data
        end
      end

      params_hash = Hash[param_key.zip(param_value)]
    end

    params_hash
  end

  def markdown_table_data(pg_result)
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

    table_headers = pg_result.fields.map { |c| " #{c.gsub("_id", "")} |" }.join
    table_body = pg_result.fields.size.times.map { " :-----: |" }.join

    "|#{table_headers}\n|#{table_body}\n#{result_data.join}"
  end

  def build_report_pms(query, table = "", usernames = [])
    pms = []
    usernames.flatten.compact.uniq.each do |username|
      pm = {}
      pm["title"] = "Scheduled Report for #{query.name}"
      pm["target_usernames"] = Array(username)
      pm["raw"] = "Hi #{username}, your data explorer report is ready.\n\n" +
        "Query Name:\n#{query.name}\n\nHere are the results:\n#{table}\n\n" +
        "<a href='/admin/plugins/explorer?id=#{query.id}'>View query in Data Explorer</a>\n\n" +
        "Report created at #{Time.zone.now.strftime("%Y-%m-%d at %H:%M:%S")} (#{Time.zone.name})"
      pms << pm
    end
    pms
  end
end
