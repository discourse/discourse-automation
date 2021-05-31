# frozen_string_literal: true

require 'rails_helper'

describe 'TopicRequiredWords' do
  fab!(:user) { Fabricate(:user) }
  fab!(:topic) { Fabricate(:topic) }
  let!(:automation) do
    DiscourseAutomation::Automation.create!(
      name: 'Ensure word is present',
      script: 'topic_required_words',
      trigger: 'topic',
      last_updated_by_id: Discourse.system_user.id
    )
  end

  context 'updating trigger' do
    it 'updates the custom field' do
      automation.upsert_field!('restricted_topic', 'text', { text: topic.id }, target: 'trigger')
      expect(topic.custom_fields['discourse_automation_id']).to eq(automation.id)

      new_topic = create_topic
      automation.upsert_field!('restricted_topic', 'text', { text: new_topic.id }, target: 'trigger')
      expect(new_topic.custom_fields['discourse_automation_id']).to eq(automation.id)
    end
  end
end
