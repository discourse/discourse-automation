# frozen_string_literal: true

describe "Automation screen", type: :system, js: true do
  fab!(:user) { Fabricate(:admin) }
  fab!(:automation_1) { Fabricate(:automation, trigger: :foo) }

  before do
    SiteSetting.discourse_automation_enabled = true
  end

  context "the trigger can be triggered manually" do
    before do
      DiscourseAutomation::Triggerable.add("foo") do
        enable_manual_trigger
      end
    end

    it "shows a manual trigger button" do
      sign_in(user)
      visit("/admin/plugins/discourse-automation/#{automation_1.id}")

      expect(page).to have_css(".trigger-now-btn")
    end
  end

  context "the trigger can’t be triggered manually" do
    before do
      DiscourseAutomation::Triggerable.add("foo")
    end

    it "shows a manual trigger button" do
      sign_in(user)
      visit("/admin/plugins/discourse-automation/#{automation_1.id}")

      expect(page).to have_css(".discourse-automation-form.edit")
      expect(page).not_to have_css(".trigger-now-btn")
    end
  end
end
