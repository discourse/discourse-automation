# frozen_string_literal: true

require_relative "../discourse_automation_helper"

describe "topic_created" do
  before do
    SiteSetting.discourse_automation_enabled = true
  end

  fab!(:user) { Fabricate(:user) }
  let(:basic_topic_params) do
    {
      title: "hello planet",
      raw: "my name is fred",
      archetype_id: 1
    }
  end
  fab!(:automation) do
    Fabricate(:automation, trigger: DiscourseAutomation::Triggerable::TOPIC_CREATED)
  end

  context "when creating a topic" do
    it "fires the trigger" do
      list = capture_contexts { PostCreator.create(user, basic_topic_params) }

      expect(list.length).to eq(1)
      expect(list[0]["kind"]).to eq("topic_created")
    end

    context "when trust_levels are restricted" do
      before do
        automation.upsert_field!(
          "valid_trust_levels",
          "trust-levels",
          { value: [2] },
          target: "trigger",
        )
      end

      context "when trust level is allowed" do
        it "fires the trigger" do
          list =
            capture_contexts do
              user.trust_level = TrustLevel[2]
              user.save!
              PostCreator.create(user, basic_topic_params)
            end

          expect(list.length).to eq(1)
          expect(list[0]["kind"]).to eq("topic_created")
        end
      end

      context "when trust level is not allowed" do
        it "doesn’t fire the trigger" do
          list =
            capture_contexts do
              user.trust_level = TrustLevel[1]
              user.save!
              PostCreator.create(user, basic_topic_params)
            end

          expect(list).to be_blank
        end
      end
    end
  end
end
