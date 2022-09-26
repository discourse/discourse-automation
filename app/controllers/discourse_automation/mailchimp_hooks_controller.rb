# frozen_string_literal: true

module DiscourseAutomation
  class MailchimpHooksController < ApplicationController
    def added_to_list
      params.require(:data)
      data = JSON.parse(params[:data])
      email = data["email"]

      raise Discourse::NotFound unless email

      user = User.find_by_email(email)

      raise Discourse::NotFound unless user

      update_user_custom_field(user, data["list_id"], true)

      render json: success_json
    end

    def removed_from_list
      params.require(:data)
      data = JSON.parse(params[:data])
      email = data["email"]

      raise Discourse::NotFound unless email

      user = User.find_by_email(email)

      raise Discourse::NotFound unless user

      update_user_custom_field(user, data["list_id"], true)

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