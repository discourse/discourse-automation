# frozen_string_literal: true

require_relative '../discourse_automation_helper'

describe 'AddToMailingList' do
  fab!(:user) { Fabricate(:user) }
  let!(:server_name) { 'user1' }
  let!(:list_id) { 'list_id1232' }
  let!(:md5) { Digest::MD5.hexdigest(user.email) }
  let!(:api_key) { '12121231' }
  let!(:basic_url) { "https://#{server_name}.api.mailchimp.com/" }
  fab!(:automation) { Fabricate(:automation, script: DiscourseAutomation::Scriptable::ADD_TO_MAILING_LIST, trigger: DiscourseAutomation::Triggerable::USER) }

  before do
    SiteSetting.discourse_automation_enabled = true
    automation.upsert_field!('description', 'text', { value: 'description' }, target: 'script')
    automation.upsert_field!('server_name', 'text', { value: server_name }, target: 'script')
    automation.upsert_field!('list_id', 'text', { value: list_id }, target: 'script')
    automation.upsert_field!('api_key', 'text', { value: api_key }, target: 'script')
  end

  describe 'When user custom field is true' do
    context 'user is subscribed' do
      let!(:get_stub) do
        stub_request(:get, "#{basic_url}3.0/lists/#{list_id}/members/#{md5}?apikey=#{api_key}").to_return(status: 200, body: {
          status: "subscribed"
        }.to_json, headers: {})
      end

      let!(:post_stub) do
        stub_request(:post, "#{basic_url}3.0/lists/#{list_id}/members").to_return(status: 200, body: {
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
        user.custom_fields["add_to_mailing_list_#{list_id}"] = true
      end

      it 'checks if user is subscribed' do
        automation.trigger!('user' => user)
        expect(get_stub).to have_been_requested.once
      end

      it 'doesnt adds user again' do
        automation.trigger!('user' => user)
        expect(post_stub).not_to have_been_requested.once
      end
    end

    context 'user is unsubscribed' do
      let!(:get_stub) do
        stub_request(:get, "#{basic_url}3.0/lists/#{list_id}/members/#{md5}?apikey=#{api_key}").to_return(status: 200, body: {
          status: "unsubscribed"
        }.to_json, headers: {})
      end

      let!(:post_stub) do
        stub_request(:post, "#{basic_url}3.0/lists/#{list_id}/members").to_return(status: 200, body: {
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

      let!(:put_stub) do
        stub_request(:put, "#{basic_url}3.0/lists/#{list_id}/members/#{md5}").to_return(status: 200, body: {
          status: "subscribed"
        }.to_json, headers: {
          :Authorization => "Basic #{api_key}",
          "content-type" => "application/json"
        })
      end

      before do
        user.custom_fields["add_to_mailing_list_#{list_id}"] = true
      end

      it 'checks if user is subscribed' do
        automation.trigger!('user' => user)
        expect(get_stub).to have_been_requested.once
      end

      it 'doesnt adds user again' do
        automation.trigger!('user' => user)
        expect(post_stub).not_to have_been_requested.once
      end

      it 'changes user subscription status' do
        automation.trigger!('user' => user)
        expect(put_stub).to have_been_requested.once
      end
    end

    context 'user is not registered to mailchimp' do
      let!(:get_stub) do
        stub_request(:get, "#{basic_url}3.0/lists/#{list_id}/members/#{md5}?apikey=#{api_key}").to_return(status: 200, body: {
          status: 404
        }.to_json, headers: {})
      end

      let!(:post_stub) do
        stub_request(:post, "#{basic_url}3.0/lists/#{list_id}/members").to_return(status: 200, body: {
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

      let!(:put_stub) do
        stub_request(:put, "#{basic_url}3.0/lists/#{list_id}/members/#{md5}").to_return(status: 200, body: {
          status: "subscribed"
        }.to_json, headers: {
          :Authorization => "Basic #{api_key}",
          "content-type" => "application/json"
        })
      end

      before do
        user.custom_fields["add_to_mailing_list_#{list_id}"] = true
      end

      it 'checks if user is subscribed' do
        automation.trigger!('user' => user)
        expect(get_stub).to have_been_requested.once
      end

      it 'adds user to mailchimp' do
        automation.trigger!('user' => user)
        expect(post_stub).to have_been_requested.once
      end

      it 'doesnt changes user subscription status' do
        automation.trigger!('user' => user)
        expect(put_stub).not_to have_been_requested.once
      end
    end
  end

  describe 'When user custom field is false' do
    context 'user is subscribed' do
      let!(:get_stub) do
        stub_request(:get, "#{basic_url}3.0/lists/#{list_id}/members/#{md5}?apikey=#{api_key}").to_return(status: 200, body: {
          status: "subscribed"
        }.to_json, headers: {})
      end

      let!(:post_stub) do
        stub_request(:post, "#{basic_url}3.0/lists/#{list_id}/members").to_return(status: 200, body: {
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

      let!(:put_stub) do
        stub_request(:put, "#{basic_url}3.0/lists/#{list_id}/members/#{md5}").to_return(status: 200, body: {
          status: "unsubscribed"
        }.to_json, headers: {
          :Authorization => "Basic #{api_key}",
          "content-type" => "application/json"
        })
      end

      before do
        user.custom_fields["add_to_mailing_list_#{list_id}"] = false
      end

      it 'checks if user is subscribed' do
        automation.trigger!('user' => user)
        expect(get_stub).to have_been_requested.once
      end

      it 'doesnt adds user again' do
        automation.trigger!('user' => user)
        expect(post_stub).not_to have_been_requested.once
      end

      it 'changes user subscription status' do
        automation.trigger!('user' => user)
        expect(put_stub).to have_been_requested.once
      end
    end

    context 'user is unsubscribed' do
      let!(:get_stub) do
        stub_request(:get, "#{basic_url}3.0/lists/#{list_id}/members/#{md5}?apikey=#{api_key}").to_return(status: 200, body: {
          status: "unsubscribed"
        }.to_json, headers: {})
      end

      let!(:post_stub) do
        stub_request(:post, "#{basic_url}3.0/lists/#{list_id}/members").to_return(status: 200, body: {
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

      let!(:put_stub) do
        stub_request(:put, "#{basic_url}3.0/lists/#{list_id}/members/#{md5}").to_return(status: 200, body: {
          status: "subscribed"
        }.to_json, headers: {
          :Authorization => "Basic #{api_key}",
          "content-type" => "application/json"
        })
      end

      before do
        user.custom_fields["add_to_mailing_list_#{list_id}"] = false
      end

      it 'checks if user is subscribed' do
        automation.trigger!('user' => user)
        expect(get_stub).to have_been_requested.once
      end

      it 'doesnt adds user again' do
        automation.trigger!('user' => user)
        expect(post_stub).not_to have_been_requested.once
      end

      it 'doesnt changes user subscription status' do
        automation.trigger!('user' => user)
        expect(put_stub).not_to have_been_requested.once
      end
    end

    context 'user is not registered to mailchimp' do
      let!(:get_stub) do
        stub_request(:get, "#{basic_url}3.0/lists/#{list_id}/members/#{md5}?apikey=#{api_key}").to_return(status: 200, body: {
          status: 404
        }.to_json, headers: {})
      end

      let!(:post_stub) do
        stub_request(:post, "#{basic_url}3.0/lists/#{list_id}/members").to_return(status: 200, body: {
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

      let!(:put_stub) do
        stub_request(:put, "#{basic_url}3.0/lists/#{list_id}/members/#{md5}").to_return(status: 200, body: {
          status: "subscribed"
        }.to_json, headers: {
          :Authorization => "Basic #{api_key}",
          "content-type" => "application/json"
        })
      end

      before do
        user.custom_fields["add_to_mailing_list_#{list_id}"] = false
      end

      it 'checks if user is subscribed' do
        automation.trigger!('user' => user)
        expect(get_stub).to have_been_requested.once
      end

      it 'doesnt adds user to mailchimp' do
        automation.trigger!('user' => user)
        expect(post_stub).not_to have_been_requested.once
      end

      it 'doesnt changes user subscription status' do
        automation.trigger!('user' => user)
        expect(put_stub).not_to have_been_requested.once
      end
    end
  end
end
