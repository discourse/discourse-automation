# frozen_string_literal: true

# name: discourse-automation
# about: Allows admins to automate actions through scripts and triggers. Customisation is made through an automatically generated UI.
# meta_topic_id: 195773
# version: 0.1
# authors: jjaffeux
# url: https://github.com/discourse/discourse-automation

after_initialize do
  class ProblemCheck::DiscourseAutomation < ProblemCheck
    self.priority = "low"

    def call
      problem
    end

    private

    def message
      "The discourse-automation plugin has been integrated into discourse core. Please remove the plugin from your app.yml and rebuild your container."
    end
  end

  register_problem_check ProblemCheck::DiscourseAutomation
end
