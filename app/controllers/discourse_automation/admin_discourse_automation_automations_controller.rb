# frozen_string_literal: true

module DiscourseAutomation
  class AdminDiscourseAutomationAutomationsController < ::ApplicationController
    def index
      automations = DiscourseAutomation::Automation.all
      serializer = ActiveModel::ArraySerializer.new(
        automations,
        each_serializer: DiscourseAutomation::AutomationSerializer,
        root: 'automations'
      ).as_json
      render_json_dump(serializer)
    end

    def show
      automation = DiscourseAutomation::Automation.find(params[:id])
      render_serialized_automation(automation)
    end

    def create
      automation_params = params.require(:automation).permit(:name, :script)
      automation = DiscourseAutomation::Automation.create!(
        automation_params.merge(last_updated_by_id: current_user.id)
      )
      render_serialized_automation(automation)
    end

    def update
      automation = DiscourseAutomation::Automation.find(params[:id])

      if automation.trigger != params[:automation][:trigger]
        request.parameters[:automation][:fields] = []
      end

      automation.fields.destroy_all

      automation.update!(
        request
          .parameters[:automation]
          .slice(:name, :id, :script, :trigger, :enabled)
          .merge(last_updated_by_id: current_user.id)
      )

      Array(request.parameters[:automation][:fields]).each do |field|
        automation.upsert_field!(field[:name], field[:component], field[:metadata], target: field[:target])
      end

      render_serialized_automation(automation)
    end

    def destroy
      automation = DiscourseAutomation::Automation.find(params[:id])
      automation.destroy!
      render json: success_json
    end

    private

    def render_serialized_automation(automation)
      serializer = DiscourseAutomation::AutomationSerializer.new(
        automation,
        root: 'automation'
      ).as_json
      render_json_dump(serializer)
    end
  end
end
