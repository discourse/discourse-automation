# frozen_string_literal: true

require_relative '../discourse_automation_helper'

describe 'AppendLastCheckedBy' do
  fab!(:post) { Fabricate(:post, raw: 'this is a post with no edit') }
  fab!(:moderator) { Fabricate(:moderator) }

  fab!(:automation) do
    Fabricate(
      :automation,
      script: DiscourseAutomation::Scriptable::APPEND_LAST_CHECKED_BY
    )
  end

  def trigger_automation(post)
    cooked = automation.trigger!('post' => post, 'cooked' => post.cooked)
    checked_at = post.updated_at + 1.hour
    date_time = checked_at.strftime("%Y-%m-%dT%H:%M:%SZ")
    [cooked, checked_at, date_time]
  end

  context "#trigger!" do
    it 'works for newly created post' do
      cooked, checked_at, date_time = trigger_automation(post)

      expect(cooked.include?("<blockquote class=\"discourse-automation\">")).to be_truthy
      expect(cooked.include?("<details><summary>Check document</summary>Perform check on document: <input type=\"button\" value=\"Done\" class=\"btn btn-checked\"></details>")).to be_truthy
    end

    it 'works for checked post' do
      topic = post.topic
      topic.custom_fields[DiscourseAutomation::TOPIC_LAST_CHECKED_BY] = moderator.username
      topic.custom_fields[DiscourseAutomation::TOPIC_LAST_CHECKED_AT] = post.updated_at + 1.hour
      topic.save_custom_fields

      cooked, checked_at, date_time = trigger_automation(post)

      expect(cooked.include?("Last checked by <a class=\"mention\" href=\"/u/#{moderator.username}\">@#{moderator.username}</a>")).to be_truthy
      expect(cooked.include?("<span data-date=\"#{checked_at.to_date.to_s}\" data-time=\"#{checked_at.strftime("%H:%M:%S")}\" class=\"discourse-local-date\" data-timezone=\"UTC\" data-email-preview=\"#{date_time} UTC\">#{date_time}</span>")).to be_truthy
    end
  end
end
