class CalendarAssistant
  module CLI
    class Config < CalendarAssistant::Config
      class TomlParseFailure < CalendarAssistant::BaseException;
      end
      class NoConfigFileToPersist < CalendarAssistant::BaseException;
      end

      CONFIG_FILE_PATH = File.join (ENV['CA_HOME'] || ENV["HOME"]), ".calendar-assistant"
      attr_reader :config_file_path

      def initialize options: {},
                     config_file_path: CONFIG_FILE_PATH,
                     defaults: DEFAULT_SETTINGS


        @config_file_path = config_file_path

        user_config = if File.exist? config_file_path
                         begin
                           FileUtils.chmod 0600, config_file_path
                           TOML.load_file config_file_path
                         rescue Exception => e
                           raise TomlParseFailure, "could not parse #{config_file_path}: #{e}"
                         end
                       else
                         Hash.new
                       end
        super(options: options, defaults: defaults, user_config: user_config)
      end

      def profile_name
        super.tap do |token|
          persist!
        end
      end

      def persist!
        if config_file_path.nil?
          raise NoConfigFileToPersist, "Cannot persist config when there's no config file"
        end

        content = TOML::Generator.new(user_config).body

        File.open(config_file_path, "w") do |f|
          f.write content
        end
      end
    end
  end
end