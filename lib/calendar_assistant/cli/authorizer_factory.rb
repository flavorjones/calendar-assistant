class CalendarAssistant
  module CLI
    class AuthorizerFactory
      def self.get(profile_name, config)
        token_type = config.token_type_store.load(profile_name) || "google"

        case token_type

        when "google"
          CalendarAssistant::CLI::Authorizers::Google.new(profile_name, config.token_store, config.token_type_store)
        else

        end
      end
    end
  end
end
