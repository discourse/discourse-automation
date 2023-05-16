# frozen_string_literal: true

require_relative "../discourse_automation_helper"

describe "PostCreatedEdited" do
  before { SiteSetting.discourse_automation_enabled = true }

  let(:basic_topic_params) do
    { title: "hello world topic", raw: "my name is fred", archetype_id: 1 }
  end
  fab!(:user) { Fabricate(:user) }
  fab!(:automation) do
    Fabricate(:automation, trigger: DiscourseAutomation::Triggerable::POST_CREATED_EDITED)
  end

  context "when editing/creating a post" do
    it "fires the trigger" do
      post = nil

      list = capture_contexts { post = PostCreator.create(user, basic_topic_params) }

      expect(list.length).to eq(1)
      expect(list[0]["kind"]).to eq("post_created_edited")
      expect(list[0]["action"].to_s).to eq("create")

      list = capture_contexts { post.revise(post.user, raw: "this is another cool topic") }

      expect(list.length).to eq(1)
      expect(list[0]["kind"]).to eq("post_created_edited")
      expect(list[0]["action"].to_s).to eq("edit")
    end

    context "when trust_levels are restricted" do
      before do
        automation.upsert_field!(
          "valid_trust_levels",
          "trust-levels",
          { value: [0] },
          target: "trigger",
        )
      end

      context "when trust level is allowed" do
        it "fires the trigger" do
          list =
            capture_contexts do
              user.trust_level = TrustLevel[0]
              PostCreator.create(user, basic_topic_params)
            end

          expect(list.length).to eq(1)
          expect(list[0]["kind"]).to eq("post_created_edited")
        end
      end

      context "when trust level is not allowed" do
        it "doesn’t fire the trigger" do
          list =
            capture_contexts do
              user.trust_level = TrustLevel[1]
              PostCreator.create(user, basic_topic_params)
            end

          expect(list).to be_blank
        end
      end
    end

    context "when category is restricted" do
      before do
        automation.upsert_field!(
          "restricted_category",
          "category",
          { value: Category.first.id },
          target: "trigger",
        )
      end

      context "when category is allowed" do
        it "fires the trigger" do
          list =
            capture_contexts do
              PostCreator.create(user, basic_topic_params.merge({ category: Category.first.id }))
            end

          expect(list.length).to eq(1)
          expect(list[0]["kind"]).to eq("post_created_edited")
        end
      end

      context "when category is not allowed" do
        fab!(:category) { Fabricate(:category) }

        it "doesn’t fire the trigger" do
          list =
            capture_contexts do
              PostCreator.create(user, basic_topic_params.merge({ category: category.id }))
            end

          expect(list).to be_blank
        end
      end
    end

    context "when action_type is set to create" do
      before do
        automation.upsert_field!("action_type", "choices", { value: "created" }, target: "trigger")
      end

      it "fires the trigger only for create" do
        post = nil

        list = capture_contexts { post = PostCreator.create(user, basic_topic_params) }

        expect(list.length).to eq(1)
        expect(list[0]["kind"]).to eq("post_created_edited")
        expect(list[0]["action"].to_s).to eq("create")

        list = capture_contexts { post.revise(post.user, raw: "this is another cool topic") }

        expect(list.length).to eq(0)
      end
    end

    context "when action_type is set to edit" do
      before do
        automation.upsert_field!("action_type", "choices", { value: "edited" }, target: "trigger")
      end

      it "fires the trigger only for edit" do
        post = nil

        list = capture_contexts { post = PostCreator.create(user, basic_topic_params) }

        expect(list.length).to eq(0)

        list = capture_contexts { post.revise(post.user, raw: "this is another cool topic") }

        expect(list.length).to eq(1)
        expect(list[0]["kind"]).to eq("post_created_edited")
        expect(list[0]["action"].to_s).to eq("edit")
      end
    end
  end
end
