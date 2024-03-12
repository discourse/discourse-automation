# frozen_string_literal: true

DiscourseAutomation::Scriptable::POST = "post"

DiscourseAutomation::Scriptable.add(DiscourseAutomation::Scriptable::POST) do
  version 1

  placeholder :creator_username

  field :creator, component: :user
  field :creator, component: :user, triggerable: :user_updated, accepted_contexts: [:updated_user]

  field :topic, component: :text, required: true
  field :post, component: :post, required: true, accepts_placeholders: true

  placeholder :creator_username
  placeholder :updated_user_username, triggerable: :user_updated
  placeholder :updated_user_name, triggerable: :user_updated

  triggerables %i[recurring point_in_time user_updated]

  script do |context, fields, automation|
    creator_username = fields.dig("creator", "value")
    creator_username = context["user"]&.username if creator_username == :updated_user
    creator_username ||= Discourse.system_user.username

    topic_id = fields.dig("topic", "value")
    post_raw = fields.dig("post", "value")

    placeholders = { creator_username: creator_username }.merge(context["placeholders"] || {})
    creator = User.find_by(username: creator_username)
    topic = Topic.find_by(id: topic_id)

    if context["kind"] == DiscourseAutomation::Triggerable::USER_UPDATED
      user = context["user"]
      user_data = context["user_data"]
      user_profile_data = user_data[:profile_data]
      user_custom_fields = {}
      user_data[:custom_fields]&.each do |k, v|
        user_custom_fields[k.gsub(/\s+/, "_").underscore] = v
      end

      user = User.find(context["user"].id)
      placeholders["username"] = user.username
      placeholders["name"] = user.name
      placeholders["updated_user_username"] = user.username
      placeholders["updated_user_name"] = user.name
      placeholders = placeholders.merge(user_profile_data, user_custom_fields)
    end

    post_raw = utils.apply_placeholders(post_raw, placeholders)

    new_post = PostCreator.new(creator, topic_id: topic_id, raw: post_raw).create! if creator &&
      topic

    if context["kind"] == DiscourseAutomation::Triggerable::USER_UPDATED && new_post.persisted?
      user.user_custom_fields.create(name: automation.name, value: "true")
    end
  end
end
