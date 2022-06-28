# frozen_string_literal: true

DiscourseAutomation::Scriptable::APPEND_LAST_CHECKED_BY = 'append_last_checked_by'

DiscourseAutomation::Scriptable.add(DiscourseAutomation::Scriptable::APPEND_LAST_CHECKED_BY) do
  version 1

  triggerables [:after_post_cook]

  script do |context|
    post = context['post']

    cooked = context['cooked']
    doc = Loofah.fragment(cooked)
    node = doc.document.create_element("div")

    summary_tag = "<summary>#{I18n.t("discourse_automation.scriptables.append_last_checked_by.summary")}</summary>"
    button_tag = "<input type=\"button\" value=\"#{I18n.t("discourse_automation.scriptables.append_last_checked_by.button_text")}\" class=\"btn btn-checked\" />"
    node.inner_html = "<details>#{summary_tag}#{I18n.t("discourse_automation.scriptables.append_last_checked_by.details")}#{button_tag}</details>"
    node.inner_html = "<p></p>" + node.inner_html
    doc.add_child(node)

    doc.try(:to_html)
  end
end
