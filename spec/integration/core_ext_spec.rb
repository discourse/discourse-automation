# frozen_string_literal: true

require_relative '../discourse_automation_helper'

describe 'Core extensions' do
  describe 'post custom fields' do
    it 'supports discourse_automation_ids' do
      post = create_post
      post.create_singular(DiscourseAutomation::CUSTOM_FIELD, 1, [:integer])

      expect(post.reload.custom_fields[DiscourseAutomation::CUSTOM_FIELD]).to eq([1])

      post.create_singular(DiscourseAutomation::CUSTOM_FIELD, 2, [:integer])

      expect(post.reload.custom_fields[DiscourseAutomation::CUSTOM_FIELD]).to eq([1, 2])

      PostCustomField.where(post_id: post.id, name: DiscourseAutomation::CUSTOM_FIELD).delete_all

      expect(post.reload.custom_fields[DiscourseAutomation::CUSTOM_FIELD]).to be(nil)

      post.create_singular(DiscourseAutomation::CUSTOM_FIELD, 1, [:integer])
      post.create_singular(DiscourseAutomation::CUSTOM_FIELD, 1, [:integer])
      post.create_singular(DiscourseAutomation::CUSTOM_FIELD, 1, [:integer])
      post.create_singular(DiscourseAutomation::CUSTOM_FIELD, 1, [:integer])

      expect(post.reload.custom_fields[DiscourseAutomation::CUSTOM_FIELD]).to eq([1])
    end
  end

  describe 'topic custom fields' do
    it 'supports discourse_automation_ids' do
      topic = create_topic
      topic.create_singular(DiscourseAutomation::CUSTOM_FIELD, 1, [:integer])

      expect(topic.reload.custom_fields[DiscourseAutomation::CUSTOM_FIELD]).to eq([1])

      topic.create_singular(DiscourseAutomation::CUSTOM_FIELD, 2, [:integer])

      expect(topic.reload.custom_fields[DiscourseAutomation::CUSTOM_FIELD]).to eq([1, 2])

      TopicCustomField.where(topic_id: topic.id, name: DiscourseAutomation::CUSTOM_FIELD).delete_all

      expect(topic.reload.custom_fields[DiscourseAutomation::CUSTOM_FIELD]).to be(nil)

      topic.create_singular(DiscourseAutomation::CUSTOM_FIELD, 1, [:integer])
      topic.create_singular(DiscourseAutomation::CUSTOM_FIELD, 1, [:integer])
      topic.create_singular(DiscourseAutomation::CUSTOM_FIELD, 1, [:integer])
      topic.create_singular(DiscourseAutomation::CUSTOM_FIELD, 1, [:integer])

      expect(topic.reload.custom_fields[DiscourseAutomation::CUSTOM_FIELD]).to eq([1])
    end
  end

  describe 'user custom fields' do
    it 'supports discourse_automation_ids' do
      user = create_user
      user.create_singular(DiscourseAutomation::CUSTOM_FIELD, 1, [:integer])

      expect(user.reload.custom_fields[DiscourseAutomation::CUSTOM_FIELD]).to eq([1])

      user.create_singular(DiscourseAutomation::CUSTOM_FIELD, 2, [:integer])

      expect(user.reload.custom_fields[DiscourseAutomation::CUSTOM_FIELD]).to eq([1, 2])

      UserCustomField.where(user_id: user.id, name: DiscourseAutomation::CUSTOM_FIELD).delete_all

      expect(user.reload.custom_fields[DiscourseAutomation::CUSTOM_FIELD]).to be(nil)

      user.create_singular(DiscourseAutomation::CUSTOM_FIELD, 1, [:integer])
      user.create_singular(DiscourseAutomation::CUSTOM_FIELD, 1, [:integer])
      user.create_singular(DiscourseAutomation::CUSTOM_FIELD, 1, [:integer])
      user.create_singular(DiscourseAutomation::CUSTOM_FIELD, 1, [:integer])

      expect(user.reload.custom_fields[DiscourseAutomation::CUSTOM_FIELD]).to eq([1])
    end
  end
end
