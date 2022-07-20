# frozen_string_literal: true

require_relative '../discourse_automation_helper'

describe DiscourseAutomation::AppendLastCheckedByController do
  describe '#post_checked' do
    fab!(:post) { Fabricate(:post) }
    fab!(:topic) { post.topic }

    it 'updates the topic custom fields' do
      admin = Fabricate(:admin)
      sign_in(admin)

      put "/append-last-checked-by/#{post.id}.json"
      expect(response.status).to eq(200)
      expect(topic.custom_fields[DiscourseAutomation::TOPIC_LAST_CHECKED_BY]).to eq(admin.username)
      expect(topic.custom_fields[DiscourseAutomation::TOPIC_LAST_CHECKED_AT]).to eq(Time.zone.now.to_s)
    end

    it 'returns error if user can not edit the post' do
      sign_in(Fabricate(:user))

      put "/append-last-checked-by/#{post.id}.json"
      expect(response.status).to eq(403)
    end
  end
end
