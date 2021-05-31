# frozen_string_literal: true

require 'rails_helper'
require_relative '../fabricators/automation_fabricator'

describe DiscourseAutomation::Automation do
  before do
    DiscourseAutomation::Scriptable.add('something_about_us') do
      script { p 'Howdy!' }
    end
  end



  describe '#trigger!' do
    context 'is not enabled' do
      fab!(:automation) { Fabricate(:automation, script: 'something_about_us', enabled: false) }

      it 'doesn’t do anything' do
        output = capture_stdout do
          automation.trigger!
        end

        expect(output).to_not include('Howdy!')
      end
    end

    context 'is enabled' do
      fab!(:automation) { Fabricate(:automation, script: 'something_about_us', enabled: true) }

      it 'runs the script' do
        output = capture_stdout do
          automation.trigger!
        end

        expect(output).to include('Howdy!')
      end
    end
  end
end
