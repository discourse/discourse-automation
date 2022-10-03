# frozen_string_literal: true

require_relative '../discourse_automation_helper'

describe 'AddToMailingList' do
  before do
    SiteSetting.discourse_automation_enabled = true
  end

  fab!(:user) { Fabricate(:user) }

  context 'when using user trigger' do
    let(:server_name) { 'user1' }
    let(:list_id) { 'list_id1232' }
    let(:md5) { Digest::MD5.hexdigest(user.email) }
    let(:api_key) { '12121231' }
    fab!(:automation) { Fabricate(:automation, script: DiscourseAutomation::Scriptable::ADD_TO_MAILING_LIST, trigger: DiscourseAutomation::Triggerable::USER) }

    before do
      user.custom_fields["add_to_mailing_list_#{list_id}"] = true
      automation.upsert_field!('description', 'text', { value: 'description' }, target: 'script')
      automation.upsert_field!('server_name', 'text', { value: server_name }, target: 'script')
      automation.upsert_field!('list_id', 'text', { value: list_id }, target: 'script')
      automation.upsert_field!('api_key', 'text', { value: api_key }, target: 'script')

      Excon::Connection.any_instance.stubs(:put)
      Excon::Connection.any_instance.stubs(:get)

    it 'requests to mailchimp' do
      Excon::Connection.any_instance.expects(:get)
      Excon::Connection.any_instance.expects(:put)

      automation.trigger!('user' => user)
    end
  end
end
