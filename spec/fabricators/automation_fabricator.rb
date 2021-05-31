# frozen_string_literal: true

Fabricator(:automation, from: DiscourseAutomation::Automation) do
  name 'My Automation'
  script DiscourseAutomation::Scriptable::SEND_PMS
  trigger DiscourseAutomation::Triggerable::TOPIC
  last_updated_by_id Discourse.system_user.id
  enabled true
end
