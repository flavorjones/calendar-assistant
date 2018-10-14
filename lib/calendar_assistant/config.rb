require "toml"

class CalendarAssistant
  class Config
    class TomlParseFailure < CalendarAssistant::BaseException ; end
    class NoConfigFileToPersist < CalendarAssistant::BaseException ; end

    CONFIG_FILE_PATH = File.join ENV["HOME"], ".calendar-assistant"

    attr_reader :config_file_path, :user_config

    def initialize config_file_path: CONFIG_FILE_PATH, config_io: nil
      if config_io.nil?
        @config_file_path = config_file_path
      end

      @user_config = if config_io
                       begin
                         TOML.load config_io.read
                       rescue Exception => e
                         raise TomlParseFailure, "could not parse IO stream: #{e}"
                       end
                     elsif File.exist? config_file_path
                       begin
                         TOML.load_file config_file_path
                       rescue Exception => e
                         raise TomlParseFailure, "could not parse #{config_file_path}: #{e}"
                       end
                     else
                       Hash.new
                     end
    end

    def [] key
      user_config[key] ||= {}
      user_config[key]
    end

    def []= key, value
      user_config[key] = value
    end

    def token_store
      CalendarAssistant::Config::TokenStore.new self
    end

    def persist!
      if config_file_path.nil?
        raise NoConfigFileToPersist, "Cannot persist config when initialized with an IO"
      end

      content = TOML::Generator.new(user_config).body

      File.open(config_file_path, "w") do |f|
        f.write content
      end
    end

    class TokenStore
      attr_reader :config

      TOKENS_KEY = "tokens"

      def initialize config
        @config = config
      end

      def delete id
        config[TOKENS_KEY].delete(id)
        config.persist!
      end

      def load id
        config[TOKENS_KEY][id]
      end

      def store id, token
        config[TOKENS_KEY][id] = token
        config.persist!
      end
    end
  end
end
