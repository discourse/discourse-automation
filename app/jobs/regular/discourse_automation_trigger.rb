# frozen_string_literal: true

module Jobs
  class DiscourseAutomationTrigger < ::Jobs::Base
    def execute(args)
      automation = DiscourseAutomation::Automation.find_by(id: args[:automation_id])

      return if !automation

      automation.running_in_background!
      automation.trigger!(args[:context])
    end
  end
end
