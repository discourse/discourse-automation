# frozen_string_literal: true

require_relative '../discourse_automation_helper'

describe DiscourseAutomation::UserBadgeGrantedHandler do
  fab!(:user) { Fabricate(:user) }
  fab!(:automation) {
    Fabricate(
      :automation,
      trigger: DiscourseAutomation::Triggerable::USER_BADGE_GRANTED
    )
  }
  fab!(:tracked_badge) { Fabricate(:badge, multiple_grant: true) }

  before do
    SiteSetting.discourse_automation_enabled = true
  end

  context 'when badge is not tracked' do
    it 'doesn’t trigger the automation' do
      list = capture_contexts do
        described_class.handle(automation, tracked_badge.id, user.id)
      end
      expect(list).to be_blank
    end
  end

  context 'when badge is tracked' do
    before do
      automation.upsert_field!('badge', 'choices', { value: tracked_badge.id }, target: 'trigger')
    end

    describe 'only trigger on first grant' do
      before do
        automation.upsert_field!('only_first_grant', 'boolean', { value: true }, target: 'trigger')
      end

      context 'when badge has been granted two times' do
        before do
          BadgeGranter.grant(tracked_badge, user)
          BadgeGranter.grant(tracked_badge, user)
        end

        it 'doesn’t trigger the automation' do
          list = capture_contexts do
            described_class.handle(automation, tracked_badge.id, user.id)
          end
          expect(list).to be_blank
        end
      end

      context 'when badge has not been granted already' do
        it 'triggers the automation' do
          list = capture_contexts do
            described_class.handle(automation, tracked_badge.id, user.id)
          end

          expect(list.length).to eq(1)
          expect(list[0]['kind']).to eq(DiscourseAutomation::Triggerable::USER_BADGE_GRANTED)
        end
      end

      context 'when user doesn’t exist' do
        it 'raises an error' do
          expect {
            described_class.handle(automation, tracked_badge.id, -999)
          }.to raise_error(ActiveRecord::RecordNotFound, /'id'=-999/)
        end
      end
    end

    it 'triggers the automation' do
      list = capture_contexts do
        described_class.handle(automation, tracked_badge.id, user.id)
      end

      expect(list.length).to eq(1)
      output = list[0]
      expect(output['kind']).to eq(DiscourseAutomation::Triggerable::USER_BADGE_GRANTED)
      expect(output['usernames']).to eq([user.username])
      expect(output['placeholders']).to eq('badge_name' => tracked_badge.name, 'grant_count' => tracked_badge.grant_count)
      expect(output['badge']['id']).to eq(tracked_badge.id)
    end
  end
end
