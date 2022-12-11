# frozen_string_literal: true
include HasSanitizableFields

DiscourseAutomation::Scriptable::SCHEDULED_EXPLORER_QUERY = 'scheduled_explorer_query'

DiscourseAutomation::Scriptable.add(DiscourseAutomation::Scriptable::SCHEDULED_EXPLORER_QUERY) do
  
  # if data explorer plugin is enabled, load queries to populate choices field
  # queries need to be added via Data Explorer plugin first to appear here
  options = !SiteSetting.data_explorer_enabled ? [] : DataExplorer::Query.where(hidden: false).map{|q|
    { id: q.id, translated_name: q.name }
  }

  field :receiver, component: :user, required: true
  field :group_id, component: :group, required: true
  field :query_id, component: :choices, required: true, extra: { content: options }
  # field :query_params, component: :key_value, value: [{"key":"months_ago","value":"1"}]

  version 1

  triggerables [:recurring]
  
  script do |context, fields, automation|
    now = Time.zone.now
    receiver = fields.dig('receiver', 'value') || Discourse.system_user.username
    group_id = fields.dig('group_id', 'value')
    query_id = fields.dig('query_id', 'value')
    # query_params = fields.dig('query_params', 'value')
    usernames = [receiver]

    unless SiteSetting.data_explorer_enabled
      Rails.logger.warn '[discourse-automation] Report requires Data Explorer plugin to be enabled'
      next
    end
  
    unless receiver.present? && user = User.find_by(username: receiver)
      Rails.logger.warn "[discourse-automation] Couldn't find user with username #{receiver}"
      next
    end
    
    unless group = Group.find_by(id: group_id)
      Rails.logger.warn "[discourse-automation] Couldn't find group with id of #{group_id}"
      next
    end

    group.users.pluck(:username).each { |username| usernames << username }

    query = DataExplorer::Query.find(query_id)
    query.update!(last_run_at: Time.now)    

    params = {} # may want to populate with key, value field for params (ie. user_id, months_ago etc)
    result = DataExplorer.run_query(query, params)
    pg_result = result[:pg_result]
    result_rows = pg_result.values
    relations, colrender = DataExplorer.add_extra_data(pg_result)
    column_names = pg_result.fields.map { |c| c.gsub('_id', '') }
    result_data = []
    
    # column names to search in place of id columns (topic_id, user_id etc)
    cols = ["name", "title", "username"]

    # find values from extra data, based on result id
    result_rows.each do |row|
      row_data = []

      row.each_with_index do |col, col_index|
        col_name = pg_result.fields[col_index]
        related = relations.dig(colrender[col_index].to_sym) if col_index < colrender.size

        if related.is_a?(ActiveModel::ArraySerializer)
          related_row = related.object.find_by(id: col)
          column = !col_name.include?("_id") ? related_row.try(col_name) : cols.find {|c| related_row.try c }
          row_data[col_index] = column.nil? ? col : related_row[column]
        else
          row_data[col_index] = col
        end
      end

      result_data << row_data.map{ |c| "<td>#{ sanitize_field(c.to_s) }</td>" }.join
    end

    # present query results in table format
    cols = column_names.map { |c| "<th>#{c}</th>" }.join
    rows = result_data.map { |row| "<tr>#{row}</tr>" }.join
    table = "<table><thead><tr>#{cols}</tr></thead><tbody>#{rows}</tbody></table>"

    # send private message with data explorer results to each user in group
    usernames.compact.uniq.each do |username|
      title = "Scheduled Report for #{query.name}"
      message = "Hi #{username}, your data explorer report is ready.\n\nQuery Name:\n#{query.name}\n\nHere are the results:\n#{table.html_safe}\n\n<a href='/admin/plugins/explorer?id=#{query_id}'>View this query in Data Explorer</a>\n\nReport created at #{Time.zone.now.strftime("%Y-%m-%d at %H:%M:%S")} (#{Time.zone.name})"

      utils.send_pm(
        {
          title: title,
          raw: message,
          target_usernames: Array(username),
        },
        automation_id: automation.id
      )
    end
  end
end
