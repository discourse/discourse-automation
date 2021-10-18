# frozen_string_literal: true

require_relative '../discourse_automation_helper'

describe DiscourseAutomation::Automation do
  describe '#trigger!' do
    context 'is not enabled' do
      fab!(:automation) { Fabricate(:automation, enabled: false) }

      it 'doesn’t do anything' do
        output = capture_stdout do
          automation.trigger!('Howdy!')
        end

        expect(output).to_not include('Howdy!')
      end
    end

    context 'is enabled' do
      fab!(:automation) { Fabricate(:automation, enabled: true) }

      it 'runs the script' do
        output = capture_stdout do
          automation.trigger!('Howdy!')
        end

        expect(output).to include('Howdy!')
      end
    end
  end

  describe '#detach_custom_field' do
    it 'expects a User/Topic/Post instance' do
      expect {
        automation_1.detach_custom_field(Invite.new)
      }.to raise_error(RuntimeError)
    end
  end

  describe '#attach_custom_field' do
    it 'expects a User/Topic/Post instance' do
      expect {
        automation_1.attach_custom_field(Invite.new)
      }.to raise_error(RuntimeError)
    end
  end

  context 'automation’s script has a required field' do
    before do
      DiscourseAutomation::Scriptable.add('required_dogs') do
        field :dog, component: :text, required: true
      end
    end

    context 'field is not filled' do
      fab!(:automation) { Fabricate(:automation, enabled: false, script: 'required_dogs') }

      context 'validating automation' do
        it 'raises an error' do
          expect {
            automation.fields.create!(name: 'dog', component: 'text', metadata: { value: nil }, target: 'script')
          }.to raise_error(ActiveRecord::RecordInvalid, /dog/)
        end
      end
    end
  end

  context 'automation’s trigger has a required field' do
    before do
      DiscourseAutomation::Triggerable.add('required_dogs') do
        field :dog, component: :text, required: true
      end
    end

    context 'field is not filled' do
      fab!(:automation) { Fabricate(:automation, enabled: false, trigger: 'required_dogs') }

      context 'validating automation' do
        it 'raises an error' do
          expect {
            automation.fields.create!(name: 'dog', component: 'text', metadata: { value: nil }, target: 'trigger')
          }.to raise_error(ActiveRecord::RecordInvalid, /dog/)
        end
      end
    end
  end
end
