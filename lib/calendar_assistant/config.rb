require "toml"

class CalendarAssistant
  class Config
    class TomlParseFailure < CalendarAssistant::BaseException ; end
    class NoConfigFileToPersist < CalendarAssistant::BaseException ; end
    class NoTokensAuthorized < CalendarAssistant::BaseException ; end
    class AccessingHashAsScalar < CalendarAssistant::BaseException ; end

    CONFIG_FILE_PATH = File.join ENV["HOME"], ".calendar-assistant"

    module Keys
      TOKENS = "tokens"
      SETTINGS = "settings"

      module Settings
        PROFILE = "profile"
        MEETING_LENGTH = "meeting-length"
        START_OF_DAY = "start-of-day"
        END_OF_DAY = "end-of-day"
      end
    end

    DEFAULT_SETTINGS = {
      Keys::Settings::MEETING_LENGTH => "30m", # ChronicDuration
      Keys::Settings::START_OF_DAY => "9am", # Chronic
      Keys::Settings::END_OF_DAY => "6pm", # Chronic
    }

    attr_reader :config_file_path, :user_config, :options, :defaults

    def initialize options: {},
                   config_file_path: CONFIG_FILE_PATH,
                   config_io: nil,
                   defaults: DEFAULT_SETTINGS
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
                         FileUtils.chmod 0600, config_file_path
                         TOML.load_file config_file_path
                       rescue Exception => e
                         raise TomlParseFailure, "could not parse #{config_file_path}: #{e}"
                       end
                     else
                       Hash.new
                     end

      @defaults = defaults
      @options = options
    end

    def profile_name
      # CLI option takes precedence
      return options[Keys::Settings::PROFILE] if options[Keys::Settings::PROFILE]

      # then a configured preference takes precedence
      default = get([Keys::SETTINGS, Keys::Settings::PROFILE])
      return default if default

      # finally we'll grab the first configured token and set that as the default
      token_names = tokens.keys
      if token_names.empty?
        raise NoTokensAuthorized, "Please run `calendar-assistant help authorize` for help."
      end
      token_names.first.tap do |new_default|
        Config.set_in_hash user_config, [Keys::SETTINGS, Keys::Settings::PROFILE], new_default
        persist!
      end
    end

    def get keypath
      rval = Config.find_in_hash(user_config, keypath)

      if rval.is_a?(Hash)
        raise AccessingHashAsScalar, "keypath #{keypath} is not a scalar"
      end

      rval
    end

    def set keypath, value
      Config.set_in_hash user_config, keypath, value
    end

    def setting setting_name
      Config.find_in_hash(options, setting_name) ||
        Config.find_in_hash(user_config, [Keys::SETTINGS, setting_name]) ||
        Config.find_in_hash(defaults, setting_name)
    end

    def settings
      setting_names = CalendarAssistant::Config::Keys::Settings.constants.map do |k|
        CalendarAssistant::Config::Keys::Settings.const_get k
      end
      setting_names.inject({}) do |settings, key|
        settings[key] = setting key
        settings
      end
    end

    def tokens
      Config.find_in_hash(user_config, Keys::TOKENS) ||
        Config.set_in_hash(user_config, Keys::TOKENS, {})
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

    private

    def self.find_in_hash hash, keypath
      current_val = hash
      keypath = keypath.split(".") unless keypath.is_a?(Array)

      keypath.each do |key|
        if current_val.has_key?(key)
          current_val = current_val[key]
        else
          current_val = nil
          break
        end
      end

      current_val
    end

    def self.set_in_hash hash, keypath, new_value
      current_hash = hash
      keypath = keypath.split(".") unless keypath.is_a?(Array)
      *path_parts, key = *keypath

      path_parts.each do |path_part|
        current_hash[path_part] ||= {}
        current_hash = current_hash[path_part]
      end

      current_hash[key] = new_value
    end
  end
end

require "calendar_assistant/config/token_store"
