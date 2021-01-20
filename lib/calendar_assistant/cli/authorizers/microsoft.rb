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

        def service
          if credentials.nil?
            raise UnauthorizedError, "Not authorized. Please run `calendar-assistant authorize #{profile_name}`"
          end

          MicrosoftGraph.new(@credentials['access_token'], @credentials['refresh_token'])
        end

        private

        def credentials
          @credentials ||= JSON.parse(refresh_tokens)
        end

        def refresh_tokens
          return nil unless config_token_store.load(profile_name)

          tokens = JSON.parse(config_token_store.load(profile_name))
          credentials = JSON.parse(File.read(CREDENTIALS_PATH))
          MicrosoftGraph::Authorizer.refresh_tokens(credentials['tenant_id'], credentials['client_id'], tokens['refresh_token']).tap do |tokens_json|
            config_token_store.store(profile_name, tokens_json)
          end
        end

        def prompt_user_for_authorization
          if !File.exists?(CREDENTIALS_PATH)
            raise NoCredentials, "No credentials found. Please run `calendar-assistant help setup` for instructions"
          end

          json = JSON.parse(File.read(CREDENTIALS_PATH))
          tenant_id = json["tenant_id"]
          client_id = json["client_id"]

          tokens_json = MicrosoftGraph::Authorizer.device_code(tenant_id, client_id, SCOPE)

          config_token_store.store(profile_name, tokens_json)
        end
      end
    end
  end
end
