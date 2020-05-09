class CalendarAssistant
  module CLI
    class Authorizer
      class NoCredentials < CalendarAssistant::BaseException; end
      class UnauthorizedError < CalendarAssistant::BaseException; end

      def initialize(profile_name, config_token_store, config_token_type_store)
        token_type = config_token_type_store.load(profile_name) || "google"

        case token_type

        when "google"
          @authorizer = CalendarAssistant::CLI::Authorizers::Google.new(profile_name, config_token_store, config_token_type_store)
        else

        end
      end

      def method_missing(m, *args, &block)
        @authorizer.send(m, *args, &block)
      end
    end
  end
end
