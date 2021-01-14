# frozen_string_literal: true

module DiscourseAutomation
  class AdminDiscourseAutomationScriptablesController < ::ApplicationController
    def index
      scriptables = DiscourseAutomation::Scriptable
        .all
        .map do |s|
          id = s.to_s.gsub(/^__scriptable_/, '')
          {
            id: id,
            name: I18n.t("discourse_automation.scriptables.#{id}.title"),
            description: I18n.t("discourse_automation.scriptables.#{id}.description"),
            doc: I18n.t("discourse_automation.scriptables.#{id}.doc"),
          }
        end

      render_json_dump(scriptables: scriptables)
    end
  end
end
