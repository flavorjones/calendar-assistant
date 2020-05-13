class CalendarAssistant
  module CLI
    class AuthorizerFactory
      def self.get(profile_name, token_type, config)
        case token_type

        when "google"
          CalendarAssistant::CLI::Authorizers::Google.new(profile_name, config.token_store)
        when "microsoft"
          CalendarAssistant::CLI::Authorizers::Microsoft.new(profile_name, config.token_store)
        else

        end
      end
    end
  end
end
