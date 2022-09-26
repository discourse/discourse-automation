# frozen_string_literal: true

module DiscourseAutomation
  class MailchimpHooksController < ApplicationController
    skip_before_action :check_xhr,
                      :preload_json,
                      :verify_authenticity_token,
                      :redirect_to_login_if_required,
                      only: [:webhook]

    def webhook
      params.require(:data)
      data = JSON.parse(params[:data])
      email = data["email"]

      user = User.find_by_email(email) if email

      if user
        update_user_custom_field(user, data["list_id"], true) if params[:type] == "subscribe"
        update_user_custom_field(user, data["list_id"], false) if params[:type] == "unsubscribe"
      end

      render json: success_json
    end

    def update_user_custom_field(user, list_id, value)
      return unless list_id

      fields = user.custom_fields.merge("add_to_mailing_list_#{list_id}" => value)
      user.custom_fields = fields
      user.save
    end
  end
end
