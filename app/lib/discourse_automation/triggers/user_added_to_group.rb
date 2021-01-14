# frozen_string_literal: true
DiscourseAutomation::Triggerable::USER_ADDED_TO_GROUP = 'user_added_to_group'

DiscourseAutomation::Triggerable.add(DiscourseAutomation::Triggerable::USER_ADDED_TO_GROUP) do
  on_update do |automation, metadata|
  end
end
