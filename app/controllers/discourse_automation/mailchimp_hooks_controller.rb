# frozen_string_literal: true

module DiscourseAutomation
  class MailchimpHooksController < ApplicationController
    skip_before_action :check_xhr,
                      :verify_authenticity_token,
                      only: [:webhook, :webhook_tester]

    def webhook_tester
      render json: success_json
    end

    def webhook
      data = params[:data]

      if data
        email = data[:email]

        user = User.find_by_email(email) if email

        update_user_custom_field(user, data[:list_id], params[:type]) if user
      end

      render json: success_json
    end

    def update_user_custom_field(user, list_id, type)
      return unless list_id

      fields = user.custom_fields

      old_value = fields["add_to_mailing_list_#{list_id}"]

      if type == "subscribe"
        fields = fields.merge("add_to_mailing_list_#{list_id}" => true)
      elsif type == "unsubscribe"
        fields = fields.merge("add_to_mailing_list_#{list_id}" => false)
      end

      user.custom_fields = fields
      user.save

      if old_value != fields["add_to_mailing_list_#{list_id}"]
        log_params = {
          details: "[Webhook Mailchimp Subscription] #{user.username} #{type}d to/from list_id: #{list_id}",
          previous_value: old_value ? "subscribed" : "unsubscribed",
          new_value: "#{type}d"
        }

        UserHistory.create!(log_params.merge(target_user_id: user.id, action: UserHistory.actions[:modify_mailing_list]))
      end
    end
  end
end
