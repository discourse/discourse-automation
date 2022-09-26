# frozen_string_literal: true

DiscourseAutomation::Scriptable::ADD_TO_MAILING_LIST = 'add_to_mailing_list'

DiscourseAutomation::Scriptable.add(DiscourseAutomation::Scriptable::ADD_TO_MAILING_LIST) do
  field :terms_and_condition_url, component: :text
  field :terms_and_condition_url_text, component: :text
  field :title, component: :text
  field :description, component: :text, required: true
  field :server_name, component: :text, required: true
  field :list_id, component: :text, required: true
  field :api_key, component: :text, required: true

  version 1

  triggerables [:mailing_list]

  script do |context, fields, automation|
    list_id = fields["list_id"].dig("value")
    server_name = fields["list_id"].dig("value")
    user = context['user']

    next if !server_name
    next if !list_id
    next if !user

    custom_field = !!user.custom_fields["add_to_mailing_list_#{list_id}"]

    mailchimp = DiscourseAutomation::Mailchimp.new(user, automation)

    subscription = mailchimp.is_subscribed?

    is_subscribed = subscription['status'] == "subscribed"

    if is_subscribed != custom_field
      response = mailchimp.add_user_to_mailing_list(user, automation) if custom_field && subscription['status'] == 404

      response = mailchimp.update_subscription_from_mailing_list(user, automation, custom_field) if subscription['status'] != 404

      expected_status = custom_field ? "subscribed" : "unsubscribed"

      if response["status"] != expected_status
        user.custom_fields["add_to_mailing_list_#{list_id}"] = !custom_field
        user.save!
      end
    end
  end
end
