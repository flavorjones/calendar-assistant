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

      def authorizer(profile_name: config.profile_name, config: @config)
        @authorizer[profile_name] ||= begin
                                        token_type = config.token_type_store.load(profile_name)
                                        if token_type == nil
                                          out.puts <<~EOT
                                                   Services:
                                                     1) Google Calendar
                                                     2) Outlook
                                                   EOT
                                          selection = out.prompt "Which service are you linking to?"
                                          token_type = case selection
                                            when "1" then "google"
                                            when "2" then "microsoft"
                                            else out.puts "Invalid selection"
                                          end
                                          config.token_type_store.store(profile_name, token_type)
                                        end

                                        AuthorizerFactory.get(profile_name, token_type, config)
                                      end
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
