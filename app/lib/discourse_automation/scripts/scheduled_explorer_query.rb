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
    query_params = fields.dig("query_params", "value")

    unless SiteSetting.data_explorer_enabled
      Rails.logger.warn "[discourse-automation] Data Explorer plugin must be enabled"
      next
    end

    unless recipients.present?
      Rails.logger.warn "[discourse-automation] Couldn't find any recipients"
      next
    end

    data_explorer_report = DataExplorerReportGenerator.new(automation)
    report_pms = data_explorer_report.generate(query_id, query_params, recipients)

    report_pms.each { |pm| utils.send_pm(pm, automation_id: automation.id) }
  end
end
