require "toml"

class CalendarAssistant
  class Config
    CONFIG_FILE_PATH = File.join ENV["HOME"], ".calendar-assistant"

    attr_reader :user_config

    def initialize config_file_path: CONFIG_FILE_PATH
      @user_config = if File.exists? config_file_path
                       TOML.load_file config_file_path
                     else
                       Hash.new
                     end
    end
  end
end
