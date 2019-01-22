class CalendarAssistant
  class Config
    autoload :TokenStore, "calendar_assistant/config/token_store"

    class NoTokensAuthorized < CalendarAssistant::BaseException;
    end
    class AccessingHashAsScalar < CalendarAssistant::BaseException;
    end

    module Keys
      TOKENS = "tokens"
      SETTINGS = "settings"

      #
      #  Settings are values that have a value in DEFAULT_SETTINGS below,
      #  and which can be overridden by entries in the user config file
      #
      module Settings
        PROFILE = "profile"               # string
        MEETING_LENGTH = "meeting-length" # ChronicDuration
        START_OF_DAY = "start-of-day"     # BusinessTime
        END_OF_DAY = "end-of-day"         # BusinessTime
        LOCATION_ICONS = "location-icons" # Location Icons
      end

      #
      #  Options are ephemeral command-line flag settings which _may_
      #  have a value in DEFAULT_SETTINGS below
      #
      module Options
        COMMITMENTS = "commitments" # bool
        JOIN = "join"               # bool
        ATTENDEES = "attendees"     # array of calendar ids (comma-delimited)
        LOCAL_STORE = "local-store" # filename
        DEBUG = "debug"             # bool
        FORMATTING = "formatting"   # Rainbow
        MUST_BE = "must-be"         # Event Predicates
        MUST_NOT_BE = "must-not-be" # Event Predicates
      end
    end

    DEFAULT_CALENDAR_ID = "primary"

    DEFAULT_SETTINGS = {
      Keys::Settings::LOCATION_ICONS => ["🗺 ", "🌎"],    # Location Icons
      Keys::Settings::MEETING_LENGTH => "30m",            # ChronicDuration
      Keys::Settings::START_OF_DAY => "9am",              # BusinessTime
      Keys::Settings::END_OF_DAY => "6pm",                # BusinessTime
      Keys::Options::ATTENDEES => [DEFAULT_CALENDAR_ID],  # array of calendar ids
      Keys::Options::FORMATTING => true,                  # Rainbow
    }

    attr_reader :user_config, :options, :defaults

    def initialize options: {},
                   user_config: {},
                   defaults: DEFAULT_SETTINGS

      @defaults = defaults
      @options = options
      @user_config = user_config
    end

    def in_env &block
      # this is totally not thread-safe
      orig_b_o_d = BusinessTime::Config.beginning_of_workday
      orig_e_o_d = BusinessTime::Config.end_of_workday
      begin
        BusinessTime::Config.beginning_of_workday = setting(Config::Keys::Settings::START_OF_DAY)
        BusinessTime::Config.end_of_workday = setting(Config::Keys::Settings::END_OF_DAY)
        yield
      ensure
        BusinessTime::Config.beginning_of_workday = orig_b_o_d
        BusinessTime::Config.end_of_workday = orig_e_o_d
      end
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
        raise CalendarAssistant::Config::NoTokensAuthorized, "Please run `calendar-assistant help authorize` for help."
      end
      token_names.first.tap do |new_default|
        Config.set_in_hash user_config, [Keys::SETTINGS, Keys::Settings::PROFILE], new_default
      end
    end

    def get keypath
      rval = Config.find_in_hash(user_config, keypath)

      if rval.is_a?(Hash)
        raise CalendarAssistant::Config::AccessingHashAsScalar, "keypath #{keypath} is not a scalar"
      end

      rval
    end

    def set keypath, value
      Config.set_in_hash user_config, keypath, value
    end

    #
    #  note that, despite the name, this method returns both options
    #  and settings
    #
    def setting setting_name
      Config.find_in_hash(options, setting_name) ||
        Config.find_in_hash(user_config, [Keys::SETTINGS, setting_name]) ||
        Config.find_in_hash(defaults, setting_name)
    end

    alias_method :[], :setting

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

    #
    #  helper method for Keys::Options::ATTENDEES
    #
    def attendees
      split_if_array(Keys::Options::ATTENDEES)
    end

    def must_be
      split_if_array(Keys::Options::MUST_BE)
    end

    def must_not_be
      split_if_array(Keys::Options::MUST_NOT_BE)
    end

    def debug?
      setting(Keys::Options::DEBUG)
    end

    def persist!
      #noop
    end

    private

    def split_if_array(key)
      a = setting(key)
      if a.is_a?(String)
        a = a.split(",")
      end
      a
    end

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
