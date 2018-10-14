require "toml"

class CalendarAssistant
  class Config
    class TomlParseFailure < CalendarAssistant::BaseException ; end

    CONFIG_FILE_PATH = File.join ENV["HOME"], ".calendar-assistant"

    attr_reader :user_config

    def initialize config_file_path: CONFIG_FILE_PATH, config_io: nil
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

    def token_store
      CalendarAssistant::TokenStore.new self
    end
  end

  class TokenStore
    attr_reader :config

    def initialize config
      @config = config
    end

    def delete id
    end

    def load id
    end

    def store id, token
    end
  end
end
