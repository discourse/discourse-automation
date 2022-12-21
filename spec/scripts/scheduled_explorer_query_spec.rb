# frozen_string_literal: true

require_relative '../discourse_automation_helper'

describe 'ScheduledExplorerQuery' do
  fab!(:automation) { Fabricate(:automation, script: DiscourseAutomation::Scriptable::SCHEDULED_EXPLORER_QUERY, trigger: 'recurring') }
  fab!(:admin_1) { Fabricate(:user, username: "johndoe", admin: true) }
  fab!(:user_1) { Fabricate(:user, username: "testuser1", admin: false) }
  let!(:group) { Group.find_by(name: "admins") }
  let!(:query) { DataExplorer::Query.find(-7) }
  let!(:recipients) { ["johndoe", "john@doe.com"] }
  let!(:pm_title) { "Scheduled Report for #{query.name}" }

  before do
    SiteSetting.data_explorer_enabled = true
    SiteSetting.discourse_automation_enabled = true

    automation.upsert_field!('query_id', 'choices', { value: "-7" }, target: 'script')
    automation.upsert_field!('recipients', 'email_group_user', { value: recipients })
    automation.upsert_field!('query_params', 'key-value', { value: ['months', '1'] })
    automation.upsert_field!('recurrence', 'period', { value: { interval: 1, frequency: 'month' } }, target: 'trigger')
    automation.upsert_field!('start_date', 'date_time', { value: 5.minutes.ago }, target: 'trigger')
  end

  context 'when using recurring trigger' do
    it 'sends the pm at recurring date_date' do
      freeze_time 1.month.from_now do
        expect {
          Jobs::DiscourseAutomationTracker.new.execute
          expect(Post.last.topic.title).to eq(pm_title)
        }.to change { Post.count }.by(1)
      end
    end

    it 'should not send to email addresses if creator lacks send to email permission' do
      expect(Guardian.new(user_1).can_send_private_messages_to_email?).to eq(false)

      automation.update(last_updated_by_id: user_1.id)
      expect(automation.trigger!).to eq(["johndoe"])
    end

    it 'should ensure that script creator with send to email permissions, can send pms to emails' do
      automation.update(last_updated_by_id: Discourse.system_user.id)
      expect(automation.trigger!).to eq(["johndoe", "john@doe.com"])
    end

    it 'should ensure admin users receive reports via pm' do
      expect(Guardian.new(admin_1).user_can_access_query?(query)).to eq(true)
      total_posts = Post.count

      automation.update(last_updated_by_id: admin_1.id)
      automation.trigger!
      expect(Post.count).to eq(total_posts + 1)
    end

    it 'should pass guardian clause for both user and group have query access' do
      expect(Guardian.new(admin_1).group_and_user_can_access_query?(group, query)).to eq(true)
    end
  end
end
