# frozen_string_literal: true

require_relative "../../db/migrate/20231022224833_update_custom_field_data.rb"

RSpec.describe UpdateCustomFieldData do
  fab!(:user_field) { Fabricate(:user_field, name: "Pseudonym") }

  context "when recurrent automation" do
    fab!(:automation) do
      Fabricate(:automation, script: "add_user_to_group_through_custom_field", trigger: "recurring")
    end
    fab!(:automation_field) do
      Fabricate(:automation_field, automation: automation, metadata: { value: user_field.id })
    end

    before do
      automation_field.update_columns(
        component: "text",
        metadata: {
          value: "user_field_#{user_field.id}",
        },
      )
    end

    it "updates metadata " do
      expect { described_class.new.up }.to change { automation_field.reload.metadata }.to(
        { "value" => user_field.id },
      )
      expect { described_class.new.down }.to change { automation_field.reload.metadata }.to(
        { "value" => "user_field_#{user_field.id}" },
      )
    end

    it "updates component" do
      expect { described_class.new.up }.to change { automation_field.reload.component }.to(
        "custom_field",
      )
      expect { described_class.new.down }.to change { automation_field.reload.component }.to("text")
    end
  end

  context "when user_first_logged_in" do
    fab!(:automation) do
      Fabricate(
        :automation,
        script: "add_user_to_group_through_custom_field",
        trigger: "user_first_logged_in",
      )
    end
    fab!(:automation_field) do
      Fabricate(:automation_field, automation: automation, metadata: { value: user_field.id })
    end

    before { automation_field.update_columns(component: "text", metadata: { value: "Pseudonym" }) }

    it "updates metadata " do
      expect { described_class.new.up }.to change { automation_field.reload.metadata }.to(
        { "value" => user_field.id },
      )
      expect { described_class.new.down }.to change { automation_field.reload.metadata }.to(
        { "value" => "Pseudonym" },
      )
    end

    it "updates component" do
      expect { described_class.new.up }.to change { automation_field.reload.component }.to(
        "custom_field",
      )
      expect { described_class.new.down }.to change { automation_field.reload.component }.to("text")
    end
  end
end
