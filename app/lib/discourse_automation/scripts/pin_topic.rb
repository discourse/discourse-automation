# frozen_string_literal: true

DiscourseAutomation::Scriptable::PIN_TOPIC = 'pin_topic'

DiscourseAutomation::Scriptable.add(DiscourseAutomation::Scriptable::PIN_TOPIC) do
  field :pinnable_topic, component: :text
  field :pinned_until, component: :date_time
  field :pinned_globally, component: :boolean

  version 1

  triggerables [:point_in_time]

  script do |_context, fields|
    topic_id = fields.dig('pinnable_topic', 'text')
    next unless topic_id

    topic = Topic.find_by(id: topic_id)
    next unless topic

    pinned_until = fields.dig('pinned_until', 'value') || ''
    topic.update_pinned(true, fields.dig('pinned_globally', 'value') || false, pinned_until)
  end
end
