module DiscourseAutomation
  class Mailchimp
    def initialize(user, automation)
      @user = user
      @automation = automation
    end

    def is_subscribed?
      response = connection.get(:path=> "3.0/lists/#{list_id}/members/#{md5}", :query => { :apikey => api_key })

      JSON.parse(response.body)
    end

    def add_user_to_mailing_list
      response = connection.post(:path => "3.0/lists/#{list_id}/members", :headers => header, :body => contact_details.to_json)

      JSON.parse(response.body)
    end

    def update_subscription_from_mailing_list(status)
      data = { status: status ? "subscribed" : "unsubscribed" }

      response = connection.put(:path => "3.0/lists/#{list_id}/members/#{md5}", :headers => header, :body => data.to_json)

      JSON.parse(response.body)
    end

    def contact_details
      {
        :email_address => @user.email,
        :status=> "subscribed",
        :merge_fields=> {
          :FNAME=> @user.name || @user.username
        }
      }
    end

    def md5
      Digest::MD5.hexdigest(@user.email)
    end

    def connection
      server_name = @automation.script_field("server_name").dig("value")
      connection = Excon.new("https://#{server_name}.api.mailchimp.com")
    end

    def list_id
      @automation.script_field("list_id").dig("value")
    end

    def api_key
      @automation.script_field("api_key").dig("value")
    end

    def header
      {
        :Authorization=>"Basic #{api_key}",
        "content-type"=>"application/json"
      }
    end
  end
end
