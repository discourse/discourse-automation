# frozen_string_literal: true

require_relative '../discourse_automation_helper'

describe 'ScheduledExplorerQuery' do
  fab!(:automation) { Fabricate(:automation, script: DiscourseAutomation::Scriptable::SCHEDULED_EXPLORER_QUERY, trigger: 'recurring') }

  before do
    SiteSetting.discourse_automation_enabled = true

    automation.upsert_field!('sender', 'user', { value: Discourse.system_user.username }, target: 'trigger')
    automation.upsert_field!('receiver', 'user', { value: Discourse.system_user.username }, target: 'trigger')
    automation.upsert_field!('group_id', 'group', { value: 1 }, target: 'trigger')
    automation.upsert_field!('query_id', 'choices', { value: -7 }, target: 'trigger')
  end

  context 'when recurring interval reached then trigger' do
    fab!(:admin_1) { Fabricate(:user, admin: true) }
    fab!(:admin_2) { Fabricate(:user, admin: true) }

    before do
      start_date = Time.now
      automation.upsert_field!('recurrence', 'period', { value: { interval: 1, frequency: 'month' }}, target: 'trigger')
      automation.upsert_field!('start_date', 'date_time', { value: start_date }, target: 'trigger')
      automation.trigger!
    end

    it 'report should be received by PM' do
      post = Post.last
      query = Query.find(-7)
      expect(post.topic.title).to eq("Scheduled Report for #{query.name}")
    end
  end

  # context 'when run from user_added_to_group trigger' do
  #   fab!(:user_1) { Fabricate(:user) }
  #   fab!(:tracked_group_1) { Fabricate(:group) }

  #   before do
  #     automation.update!(trigger: 'user_added_to_group')
  #     automation.upsert_field!('joined_group', 'group', { value: tracked_group_1.id }, target: 'trigger')
  #   end

  #   it 'creates expected PM' do
  #     expect {
  #       tracked_group_1.add(user_1)

  #       post = Post.last
  #       expect(post.topic.title).to eq("A message from #{Discourse.system_user.username}")
  #       expect(post.raw).to eq("This is a message sent to @#{user_1.username}")
  #       expect(post.topic.topic_allowed_users.exists?(user_id: user_1.id)).to eq(true)
  #       expect(post.topic.topic_allowed_users.exists?(user_id: Discourse.system_user.id)).to eq(true)
  #     }.to change { Post.count }.by(1)
  #   end
  # end
end
