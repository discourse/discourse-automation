# frozen_string_literal: true

module DiscourseAutomation
  class TriggerSerializer < ApplicationSerializer
    attributes :id, :name, :metadata

    def metadata
      (object.metadata || {}).merge(options[:trigger_metadata] || {})
    end
  end
end
