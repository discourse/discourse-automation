# frozen_string_literal: true

require_relative "../discourse_automation_helper"

describe "AutoTagTopic" do
  fab!(:topic) { Fabricate(:topic) }
  fab!(:tag1) { Fabricate(:tag, name: "tag1") }
  fab!(:tag2) { Fabricate(:tag, name: "tag2") }
  fab!(:tag3) { Fabricate(:tag, name: "tag3") }
  fab!(:admin) { Fabricate(:admin) }

  fab!(:automation) do
    Fabricate(:automation, script: DiscourseAutomation::Scriptable::AUTO_TAG_TOPIC)
  end

  context "when tags list is empty" do
    it "exits early with no error" do
      expect {
        post = create_post(topic: topic)
        automation.trigger!("post" => post)
      }.to_not raise_error
    end
  end

  context "when there are tags" do
    before { automation.upsert_field!("tags", "tags", { value: %w[tag1 tag2] }) }

    it "works" do
      post = create_post(topic: topic)
      automation.trigger!("post" => post)

      expect(topic.reload.tags.pluck(:name)).to match_array(%w[tag1 tag2])
    end

    it "does not remove existing tags" do
      post = create_post(topic: topic, tags: %w[totally])
      DiscourseTagging.tag_topic_by_names(topic, Guardian.new(admin), ["tag3"])
      automation.trigger!("post" => post)

      expect(topic.reload.tags.pluck(:name).sort).to match_array(%w[tag1 tag2 tag3])
    end
  end

  context "when bump_topic is true" do
    before { automation.upsert_field!("bump_topic", "boolean", { value: true }) }

    it "bumps the topic" do
      post = create_post(topic: topic)
      old_bumped_at = topic.reload.bumped_at
      automation.trigger!("post" => post)

      expect(topic.reload.bumped_at).not_to eq(old_bumped_at)
    end
  end

  context "when bump_topic is false" do
    before { automation.upsert_field!("bump_topic", "boolean", { value: false }) }

    it "doesn't bump the topic" do
      post = create_post(topic: topic)
      old_bumped_at = topic.reload.bumped_at
      automation.trigger!("post" => post)

      expect(topic.reload.bumped_at).to eq_time(old_bumped_at)
    end
  end
end
