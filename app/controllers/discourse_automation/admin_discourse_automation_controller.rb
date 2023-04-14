# frozen_string_literal: true

module DiscourseAutomation
  class AdminDiscourseAutomationController < ::Admin::AdminController
    requires_plugin DiscourseAutomation::PLUGIN_NAME

    def index
    end

    def new
    end

    def edit
    end
  end
end
