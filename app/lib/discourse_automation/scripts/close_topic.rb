# frozen_string_literal: true

DiscourseAutomation::Scriptable::CLOSE_TOPIC = 'close_topic'

DiscourseAutomation::Scriptable.add(DiscourseAutomation::Scriptable::CLOSE_TOPIC) do
  field :topic, component: :text, required: true
  field :message, component: :text
  field :user, component: :user

  version 1

  # FIXME: copied over from pin_topic; needs some thought
  triggerables [:point_in_time]

  script do |_context, fields|
    next unless topic_id = fields.dig('topic', 'value')
    next unless topic = Topic.find_by(id: topic_id)

    message = fields.dig('message', 'value')
    username = fields.dig('user', 'value') || Discourse.system_user.username

    utils.close_topic(topic, username: username, message: message)
  end
end
