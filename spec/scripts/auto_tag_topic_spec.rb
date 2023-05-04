# frozen_string_literal: true

require_relative "../discourse_automation_helper"

describe "AutoTagTopic" do
  fab!(:topic) { Fabricate(:topic) }
  fab!(:tag1) { Fabricate(:tag, name: "tag1") }
  fab!(:tag2) { Fabricate(:tag, name: "tag2") }

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

      expect(topic.reload.tags.pluck(:name)).to eq(%w[tag1 tag2])
    end
  end
end
