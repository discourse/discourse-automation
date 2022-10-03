# frozen_string_literal: true

require_relative '../discourse_automation_helper'

describe 'UserBadgeGranted' do
  fab!(:user) { Fabricate(:user) }
  fab!(:tracked_badge) { Fabricate(:badge) }
  fab!(:automation) {
    Fabricate(
      :automation,
      trigger: DiscourseAutomation::Triggerable::USER_BADGE_GRANTED
    )
  }

  before do
    SiteSetting.discourse_automation_enabled = true
    automation.upsert_field!('badge', 'choices', { value: tracked_badge.id }, target: 'trigger')
  end

  context 'when a badge is granted' do
    it 'fires the trigger' do
      contexts = capture_contexts do
        BadgeGranter.grant(tracked_badge, user)
      end

      expect(contexts.length).to eq(1)
      expect(contexts[0]['kind']).to eq(DiscourseAutomation::Triggerable::USER_BADGE_GRANTED)
    end
  end
end
