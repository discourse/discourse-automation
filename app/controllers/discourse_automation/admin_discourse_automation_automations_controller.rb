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
      automation = DiscourseAutomation::Automation.create!(automation_params)
      render_serialized_automation(automation)
    end

    def update
      automation = DiscourseAutomation::Automation.find(params[:id])
      automation.update!(request.parameters[:automation].slice(:name, :id, :script))

      trigger_params = request.parameters[:automation][:trigger].slice(:metadata, :name)
      unless automation.trigger
        automation.create_trigger!(trigger_params)
      end

      automation.trigger.update_with_params(trigger_params)

      Array(request.parameters[:automation][:fields]).each do |field|
        f = automation.fields.find_or_initialize_by(
          name: field[:name],
          component: field[:component]
        )
        f.update!(metadata: field[:metadata])
      end

      render_serialized_automation(automation)
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
