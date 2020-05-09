class CalendarAssistant
  module CLI
    class Authorizer
      class NoCredentials < CalendarAssistant::BaseException; end
      class UnauthorizedError < CalendarAssistant::BaseException; end

      def initialize(profile_name, config_token_store)
        @authorizer = CalendarAssistant::CLI::Authorizers::Google.new(profile_name, config_token_store)
      end

      def method_missing(m, *args, &block)
        @authorizer.send(m, *args, &block)
      end
    end
  end
end
