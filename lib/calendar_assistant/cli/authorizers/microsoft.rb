class CalendarAssistant
  module CLI
    module Authorizers
      class Microsoft
        attr_reader :profile_name, :config_token_store

        REDIRECT_URI = "https://login.microsoftonline.com/common/oauth2/nativeclient".freeze
        CREDENTIALS_PATH = File.join (ENV["CA_HOME"] || ENV["HOME"]), ".calendar-assistant.ms.client"
        SCOPE = "offline_access%20https%3A%2F%2Fgraph.microsoft.com%2Fcalendars.read".freeze

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
      end
    end
  end
end
