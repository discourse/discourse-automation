# frozen_string_literal: true
require "rails_helper"

describe DiscourseAutomation::Mailchimp do
  let!(:user) { Fabricate(:user) }
  let!(:server_name) { 'user1' }
  let!(:list_id) { 'list_id1232' }
  let!(:md5) { Digest::MD5.hexdigest(user.email) }
  let!(:api_key) { '12121231' }
  let!(:basic_url) { "https://#{server_name}.api.mailchimp.com/" }

  before do
    SiteSetting.discourse_automation_enabled = true
  end

  context "checking user subscription with mailchimp" do
    let!(:url) { "#{basic_url}3.0/lists/#{list_id}/members/#{md5}?apikey=#{api_key}" }
    fab!(:automation) { Fabricate(:automation, script: DiscourseAutomation::Scriptable::ADD_TO_MAILING_LIST, trigger: DiscourseAutomation::Triggerable::USER) }
    let!(:mailchimp_stub) do
      stub_request(:get, url).to_return(status: 200, body: { status: "subscribed" }.to_json, headers: {})
    end

    before do
      automation.upsert_field!('description', 'text', { value: 'description' }, target: 'script')
      automation.upsert_field!('server_name', 'text', { value: server_name }, target: 'script')
      automation.upsert_field!('list_id', 'text', { value: list_id }, target: 'script')
      automation.upsert_field!('api_key', 'text', { value: api_key }, target: 'script')
    end

    it "#is_subscribed?" do
      api = described_class.new(user, automation).is_subscribed?
      expect(mailchimp_stub).to have_been_requested.once
    end
  end

  context "add user to mailchimp mailing list" do
    let!(:url) { "#{basic_url}3.0/lists/#{list_id}/members" }
    fab!(:automation) { Fabricate(:automation, script: DiscourseAutomation::Scriptable::ADD_TO_MAILING_LIST, trigger: DiscourseAutomation::Triggerable::USER) }
    let!(:mailchimp_stub) do
      stub_request(:post, url).to_return(status: 200, body: {
        email_address: user.email,
        status: "subscribed",
        merge_fields: {
          FNAME: user.name || user.username
        }
      }.to_json, headers: {
        :Authorization => "Basic #{api_key}",
        "content-type" => "application/json"
      })
    end

    before do
      automation.upsert_field!('description', 'text', { value: 'description' }, target: 'script')
      automation.upsert_field!('server_name', 'text', { value: server_name }, target: 'script')
      automation.upsert_field!('list_id', 'text', { value: list_id }, target: 'script')
      automation.upsert_field!('api_key', 'text', { value: api_key }, target: 'script')
    end

    it "#add_user_to_mailing_list" do
      api = described_class.new(user, automation).add_user_to_mailing_list
      expect(mailchimp_stub).to have_been_requested.once
    end
  end

  context "updates user subscription from mailchimp mailing list" do
    let!(:url) { "#{basic_url}3.0/lists/#{list_id}/members/#{md5}" }
    fab!(:automation) { Fabricate(:automation, script: DiscourseAutomation::Scriptable::ADD_TO_MAILING_LIST, trigger: DiscourseAutomation::Triggerable::USER) }
    let!(:mailchimp_stub) do
      stub_request(:put, url).to_return(status: 200, body: { status: "subscribed" }.to_json, headers: {
        :Authorization => "Basic #{api_key}",
        "content-type" => "application/json"
      })
    end

    before do
      automation.upsert_field!('description', 'text', { value: 'description' }, target: 'script')
      automation.upsert_field!('server_name', 'text', { value: server_name }, target: 'script')
      automation.upsert_field!('list_id', 'text', { value: list_id }, target: 'script')
      automation.upsert_field!('api_key', 'text', { value: api_key }, target: 'script')
    end

    it "#update_subscription_from_mailing_list" do
      api = described_class.new(user, automation).update_subscription_from_mailing_list(true)
      expect(mailchimp_stub).to have_been_requested.once
    end
  end
end
