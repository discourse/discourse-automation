# frozen_string_literal: true

# name: discourse-automation
# about: Lets you automate actions on your Discourse Forum
# version: 0.1
# authors: jjaffeux
# url: https://github.com/discourse/discourse-automation
# transpile_js: true

after_initialize do
  AdminDashboardData.add_problem_check do
    "The discourse-automation plugin has been integrated into discourse core. Please remove the plugin from your app.yml and rebuild your container."
  end
end
