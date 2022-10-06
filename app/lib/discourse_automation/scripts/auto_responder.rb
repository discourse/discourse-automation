# frozen_string_literal: true

DiscourseAutomation::Scriptable::AUTO_RESPONDER = 'auto_responder'
DiscourseAutomation::Scriptable::AUTO_RESPONDER_TRIGGERED_IDS = 'auto_responder_triggered_ids'

DiscourseAutomation::Scriptable.add(DiscourseAutomation::Scriptable::AUTO_RESPONDER) do
  field :word_answer_list, component: :'key-value', accepts_placeholders: true
  field :answering_user, component: :user
  field :once, component: :boolean

  version 1

  triggerables [:post_created_edited, :pm_created]

  placeholder :sender_username
  placeholder :word

  script do |context, fields, automation|
    key = DiscourseAutomation::Scriptable::AUTO_RESPONDER_TRIGGERED_IDS

    answering_username = fields.dig('answering_user', 'value') || Discourse.system_user.username
    placeholders = {
      sender_username: answering_username
    }
    post = context['post']
    next if !post.topic

    if fields.dig('once', 'value') && post.topic.custom_fields[key]&.include?(automation.id)
      next
    end

    answers = Set.new
    json = fields.dig('word_answer_list', 'value')
    next if json.blank?

    tuples = JSON.parse(json)
    next if tuples.blank?

    tuples.each do |tuple|
      if tuple['key'].blank?
        answers.add(tuple)
        next
      end

      if post.is_first_post?
        if match = post.topic.title.match(/\b(#{tuple['key']})\b/i)
          tuple['key'] = match.captures.first
          answers.add(tuple)
          next
        end
      end

      if match = post.raw.match(/\b(#{tuple['key']})\b/i)
        tuple['key'] = match.captures.first
        answers.add(tuple)
      end
    end

    if answers.blank?
      next
    end

    answering_user = User.find_by(username: answering_username)
    if post.user == answering_user
      next
    end

    replies = post.replies
      .where(user_id: answering_user.id, deleted_at: nil)
      .secured(Guardian.new(post.user))

    if replies.present?
      next
    end

    answers = answers.to_a.map do |answer|
      utils.apply_placeholders(answer['value'], placeholders.merge(key: answer['key']))
    end.join("\n\n")

    value = (Array(post.topic.custom_fields[key]) << automation.id).compact.uniq
    post.topic.custom_fields[key] = value
    post.topic.save_custom_fields

    PostCreator.create!(
      answering_user,
      topic_id: post.topic.id,
      reply_to_post_number: post.post_number,
      raw: answers,
      skip_validations: true
    )
  end
end
