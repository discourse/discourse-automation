# frozen_string_literal: true

module DiscourseAutomation
  class FieldSerializer < ApplicationSerializer
    attributes :id, :component, :name, :metadata, :placeholders, :target

    def target
      object.target || scope[:target_name]
    end

    def placeholders
      field = scope[:target].fields.detect do |s|
        s[:name].to_s == object.name && s[:component].to_s == object.component
      end

      if !field || field[:accepts_placeholders].blank?
        nil
      else
        scope[:target].placeholders.map { |placeholder| "%%#{placeholder.upcase}%%" }
      end
    end
  end
end
