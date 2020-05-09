class CalendarAssistant
  module CLI
    class CommandService
      attr_reader :options, :config, :out

      def initialize(context:, options: {})
        @options = options.dup
        @options[CalendarAssistant::Config::Keys::Options::CONTEXT] ||= context.to_s

        @config = CalendarAssistant::CLI::Config.new(options: @options)
        @authorizer = {}
        @out = CalendarAssistant::CLI::Printer.new
      end

      def calendar_assistant(datespec)
        ca = CalendarAssistant.new(config, service: service)
        ca.in_env do
          yield(ca, CalendarAssistant::CLI::Helpers.parse_datespec(datespec), out)
        end
      end

      def authorizer(profile_name: config.profile_name, token_store: config.token_store, token_type_store: config.token_type_store)
        @authorizer[profile_name] ||= Authorizer.new(profile_name, token_store, token_type_store)
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
