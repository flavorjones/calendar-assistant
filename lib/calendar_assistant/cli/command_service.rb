class CalendarAssistant
  module CLI
    class CommandService
      attr_reader :options, :config, :out

      def initialize(options: {})
        @options = options
        @config  = CalendarAssistant::CLI::Config.new(options: options)
        @authorizer = {}
        @out = CalendarAssistant::CLI::Printer.new
      end

      def calendar_assistant(datespec)
        ca = CalendarAssistant.new(config, service: service)
        ca.in_env do
          yield(ca, CalendarAssistant::CLI::Helpers.parse_datespec(datespec), out)
        end
      end

      def authorizer(profile_name: config.profile_name, token_store: config.token_store)
        @authorizer[profile_name] ||= Authorizer.new(profile_name, token_store)
      end

      def service
        @service ||= begin
          if filename = config.setting(Config::Keys::Options::LOCAL_STORE)
            CalendarAssistant::LocalService.new(file: filename)
          else
            authorizer.service
          end
        end
      end
    end
  end
end