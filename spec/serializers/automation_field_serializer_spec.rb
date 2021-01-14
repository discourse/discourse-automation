# frozen_string_literal: true

require 'rails_helper'

describe DiscourseAutomation::FieldSerializer do
  let(:automation) { DiscourseAutomation::Automation.create!(script: 'gift_exchange') }

  context "with a TL0 user seen as anonymous" do
  end
end


    # attributes :id, :component, :name, :metadata, :placeholders
    #
    # def placeholders
    #   field = scope[:scriptable].fields.detect do |s|
    #     s[:name].to_s == object.name && s[:component].to_s == object.component
    #   end
    #
    #   if field && field[:placeholders].blank?
    #     nil
    #   else
    #     scope[:scriptable].placeholders.map { |placeholder| "%%#{placeholder.upcase}%%" }
    #   end
    # end
