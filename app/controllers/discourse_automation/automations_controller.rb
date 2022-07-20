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
  end
end
