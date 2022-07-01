# frozen_string_literal: true

module DiscourseAutomation
  class AutomationsController < ApplicationController
    before_action :ensure_admin, except: [:post_checked]
    before_action :ensure_logged_in, only: [:post_checked]

    def trigger
      automation = DiscourseAutomation::Automation.find(params[:id])
      automation.trigger!(params.merge(kind: DiscourseAutomation::Triggerable::API_CALL))
      render json: success_json
    end

    def post_checked
      post = Post.find(params[:post_id])
      topic = post.topic
      raise Discourse::NotFound if topic.blank?

      topic.custom_fields[DiscourseAutomation::TOPIC_LAST_CHECKED_BY] = current_user.username
      topic.custom_fields[DiscourseAutomation::TOPIC_LAST_CHECKED_AT] = Time.zone.now.to_s
      topic.save_custom_fields

      post.rebake!

      render json: success_json
    end
  end
end
