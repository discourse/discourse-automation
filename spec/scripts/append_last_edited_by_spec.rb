# frozen_string_literal: true

require_relative '../discourse_automation_helper'

describe 'AppendLastEditedBy' do
  fab!(:topic) { Fabricate(:topic) }

  fab!(:automation) do
    Fabricate(
      :automation,
      script: DiscourseAutomation::Scriptable::APPEND_LAST_EDITED_BY
    )
  end

  context "#trigger!" do
    it 'works for newly created post' do
      post = create_post(topic: topic, raw: 'this is a post with no edit')
      cooked = automation.trigger!('post' => post, 'cooked' => post.cooked)
      updated_at = post.updated_at
      date_time = updated_at.strftime("%Y-%m-%dT%H:%M:%SZ")

      expect(cooked.ends_with?("<blockquote>\n<p>Last edited by #{post.username} <span data-date=\"#{updated_at.to_date.to_s}\" data-time=\"#{updated_at.strftime("%H:%M:%S")}\" class=\"discourse-local-date\" data-timezone=\"UTC\" data-email-preview=\"#{date_time} UTC\">#{date_time}</span></p>\n</blockquote>\n</div>")).to be_truthy
    end
  end
end
