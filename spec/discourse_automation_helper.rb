require 'rails_helper'
require_relative 'fabricators/automation_fabricator'

DiscourseAutomation::Scriptable.add('something_about_us') do
  script { p 'Howdy!' }
end
