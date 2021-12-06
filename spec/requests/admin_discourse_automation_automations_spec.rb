# frozen_string_literal: true

require_relative '../discourse_automation_helper'

describe DiscourseAutomation::AdminDiscourseAutomationAutomationsController do
  fab!(:automation) { Fabricate(:automation) }

  describe '#show' do
    context 'logged in as an admin' do
      before { sign_in(Fabricate(:admin)) }

      it 'shows the automation' do
        get "/admin/plugins/discourse-automation/automations/#{automation.id}.json"
        expect(response.status).to eq(200)
        expect(response.parsed_body['automation']['id']).to eq(automation.id)
      end
    end

    context 'logged in as a regular user' do
      before { sign_in(Fabricate(:user)) }

      it 'raises a 404' do
        get "/admin/plugins/discourse-automation/automations/#{automation.id}.json"
        expect(response.status).to eq(404)
      end
    end
  end

  describe '#update' do
    context 'logged in as an admin' do
      before { sign_in(Fabricate(:admin)) }

      it 'updates the automation' do
        put "/admin/plugins/discourse-automation/automations/#{automation.id}.json", params: { automation: { trigger: 'another-trigger' } }
        expect(response.status).to eq(200)
      end

      context 'script is changed' do
        it 'nullifies the trigger' do
          put "/admin/plugins/discourse-automation/automations/#{automation.id}.json", params: {
            automation: { script: 'another_script' }
          }

          expect(automation.reload.trigger).to eq(nil)
          expect(response.status).to eq(200)
        end
      end

      context 'invalid field’s component' do
        it 'errors' do
          put "/admin/plugins/discourse-automation/automations/#{automation.id}.json", params: {
            automation: {
              script: automation.script,
              trigger: automation.trigger,
              fields: [
                { name: 'foo', component: 'bar' }
              ]
            }
          }

          expect(response.status).to eq(422)
        end
      end

      context 'required field' do
        before do
          DiscourseAutomation::Scriptable.add('test_required') do
            field :foo, component: :text, required: true
          end

          automation.update!(script: 'test_required')
        end

        it 'errors' do
          put "/admin/plugins/discourse-automation/automations/#{automation.id}.json", params: {
            automation: {
              script: automation.script,
              trigger: automation.trigger,
              fields: [{ name: 'foo', component: 'text', target: 'script', metadata: { value: nil } }]
            }
          }
          expect(response.status).to eq(422)
        end
      end

      context 'invalid field’s metadata' do
        it 'errors' do
          put "/admin/plugins/discourse-automation/automations/#{automation.id}.json", params: {
            automation: {
              script: automation.script,
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

    context 'logged in as a regular user' do
      before { sign_in(Fabricate(:user)) }

      it 'raises a 404' do
        put "/admin/plugins/discourse-automation/automations/#{automation.id}.json", params: { automation: { trigger: 'another-trigger' } }
        expect(response.status).to eq(404)
      end
    end
  end

  describe '#destroy' do
    fab!(:automation) { Fabricate(:automation) }

    context 'logged in as an admin' do
      before { sign_in(Fabricate(:admin)) }

      it 'destroys the automation' do
        delete "/admin/plugins/discourse-automation/automations/#{automation.id}.json"
        expect(DiscourseAutomation::Automation.find_by(id: automation.id)).to eq(nil)
      end
    end

    context 'logged in as a regular user' do
      before { sign_in(Fabricate(:user)) }

      it 'raises a 404' do
        delete "/admin/plugins/discourse-automation/automations/#{automation.id}.json"
        expect(response.status).to eq(404)
      end
    end
  end
end
