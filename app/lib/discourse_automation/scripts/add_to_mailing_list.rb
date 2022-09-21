# frozen_string_literal: true

DiscourseAutomation::Scriptable::ADD_TO_MAILING_LIST = 'add_to_mailing_list'

DiscourseAutomation::Scriptable.add(DiscourseAutomation::Scriptable::ADD_TO_MAILING_LIST) do
  field :terms_and_condition_url, component: :text, required: true
  field :description, component: :text, required: true

  version 1

  triggerables [:one_time_trigger]

end
