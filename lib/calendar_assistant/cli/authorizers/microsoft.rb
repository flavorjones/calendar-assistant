require 'net/http'

class CalendarAssistant
  module CLI
    module Authorizers
      class Microsoft
        attr_reader :profile_name, :config_token_store

        CREDENTIALS_PATH = File.join (ENV["CA_HOME"] || ENV["HOME"]), ".calendar-assistant.ms.client"
        SCOPE = "offline_access https://graph.microsoft.com/calendars.readwrite".freeze
        GRANT_TYPE = "urn:ietf:params:oauth:grant-type:device_code".freeze

        def initialize(profile_name, config_token_store)
          @profile_name = profile_name
          @config_token_store = config_token_store
        end

        def authorize
          credentials || prompt_user_for_authorization
        end

        private

        def credentials
          @credentials ||= get_credentials
        end

        def get_credentials
        end

        def prompt_user_for_authorization
          if !File.exists?(CREDENTIALS_PATH)
            raise NoCredentials, "No credentials found. Please run `calendar-assistant help setup` for instructions"
          end

          json = JSON.parse(File.read(CREDENTIALS_PATH))
          tenant_id = json["tenant_id"]
          client_id = json["client_id"]

          puts Rainbow("Then authorize your application to manage your calendar and copy/paste the resulting URL here:").bold

          uri = URI("https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/devicecode")
          res = Net::HTTP.post_form(uri, {
            "client_id" => client_id,
            "scope" => SCOPE
          })

          json = JSON.parse(res.body)
          interval = json["interval"]
          device_code = json["device_code"]

          puts Rainbow(json["message"]).bold
          Launchy.open("https://microsoft.com/devicelogin")

          10.times do
            sleep(interval)
            uri = URI("https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token")
            res = Net::HTTP.post_form(uri, {
              "client_id" => client_id,
              "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
              "device_code" => device_code
            })

            if res.code == "200"
              config_token_store.store(profile_name, res.body)
              break
            end
          end
        end
      end
    end
  end
end
