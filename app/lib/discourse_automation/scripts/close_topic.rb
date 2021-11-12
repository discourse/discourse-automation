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
    message = fields.dig('message', 'value')
    username = fields.dig('user', 'value') || Discourse.system_user.username

    next unless topic_id = fields.dig('topic', 'value')
    next unless topic = Topic.find_by(id: topic_id)

    user = User.find_by_username(username)
    next unless user
    next unless Guardian.new(user).can_moderate?(topic)

    topic.update_status('closed', true, user)

    if message.present?
      topic_closed_post = topic.posts.where(action_code: 'closed.enabled').last

      # FIXME: check minimum message length
      topic_closed_post.raw = message
      topic_closed_post.save!
    end
  end
end
