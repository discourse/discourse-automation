# frozen_string_literal: true

require 'rails_helper'
require_relative '../fabricators/automation_fabricator'

describe DiscourseAutomation::AdminDiscourseAutomationAutomationsController do
  let(:admin) { Fabricate(:admin) }

  before do
    sign_in(admin)
  end

  describe '#destroy' do
    let!(:automation) { Fabricate(:automation) }

    it 'destroys the bookmark' do
      delete "/admin/plugins/discourse-automation/automations/#{automation.id}.json"
      expect(DiscourseAutomation::Automation.find_by(id: automation.id)).to eq(nil)
    end
  end

  describe '#update' do
    let!(:automation) { Fabricate(:automation) }

    context 'invalid field’s component' do
      it 'errors' do
        put "/admin/plugins/discourse-automation/automations/#{automation.id}.json", params: {
          automation: {
            trigger: automation.trigger,
            fields: [
              { name: 'foo', component: 'bar' }
            ]
          }
        }

        expect(response.status).to eq(422)
      end
    end

    context 'invalid field’s metadata' do
      it 'errors' do
        put "/admin/plugins/discourse-automation/automations/#{automation.id}.json", params: {
          automation: {
            trigger: automation.trigger,
            fields: [
              { name: 'sender', component: 'users', metadata: { baz: 1 } }
            ]
          }
        }

        expect(response.status).to eq(422)
      end
    end
  end
end
