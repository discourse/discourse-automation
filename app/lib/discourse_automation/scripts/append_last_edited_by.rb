# frozen_string_literal: true

DiscourseAutomation::Scriptable::APPEND_LAST_EDITED_BY = 'append_last_edited_by'

DiscourseAutomation::Scriptable.add(DiscourseAutomation::Scriptable::APPEND_LAST_EDITED_BY) do
  version 1

  triggerables [:after_post_cook]

  script do |context|
    post = context['post']
    cooked = context['cooked']
    doc = Loofah.fragment(cooked)
    node = doc.document.create_element("p")
    doc.add_child(node)
    node = doc.document.create_element("p")
    date_time = "<span data-date=\"2022-06-24\" data-time=\"14:01:00\" class=\"discourse-local-date\" data-timezone=\"Asia/Calcutta\" data-email-preview=\"2022-06-24T08:31:00Z UTC\">2022-06-24T08:31:00Z</span>"
    node.content = I18n.t("discourse_automation.scriptables.append_last_edited_by.text", username: "", date_time: ""),
    doc.add_child(node)
    doc.try(:to_html)
  end
end
