# coding: utf-8
class CalendarAssistant
  class Config
    autoload :TokenStore, "calendar_assistant/config/token_store"

    class NoTokensAuthorized < CalendarAssistant::BaseException
    end

    class AccessingHashAsScalar < CalendarAssistant::BaseException
    end

    module Keys
      TOKENS = "tokens"
      SETTINGS = "settings"

      #
      #  Settings are values that have a value in DEFAULT_SETTINGS below,
      #  and which can be overridden by entries in the user config file
      #
      module Settings
        PROFILE = "profile"                 # string
        MEETING_LENGTH = "meeting-length"   # ChronicDuration
        START_OF_DAY = "start-of-day"       # BusinessTime
        END_OF_DAY = "end-of-day"           # BusinessTime
        LOCATION_ICON = "location-icon"     # string emoji
        NICKNAME = "nickname"               # string
        VISIBILITY = "visibility"           # Event Visibility
      end

      #
      #  Options are ephemeral command-line flag settings which _may_
      #  have a value in DEFAULT_SETTINGS below
      #
      module Options
        COMMITMENTS = "commitments" # bool
        JOIN = "join"               # bool
        CALENDARS = "calendars"     # array of calendar ids (comma-delimited)
        LOCAL_STORE = "local-store" # filename
        DEBUG = "debug"             # bool
        COLOR = "color"             # bool
        MUST_BE = "must-be"         # array of event predicates (comma-delimited)
        MUST_NOT_BE = "must-not-be" # array of event predicates (comma-delimited)
        CONTEXT = "context"         # symbol referring to command context
        FORCE = "force"             # bool
      end
    end

    DEFAULT_CALENDAR_ID = "primary"

    DEFAULT_SETTINGS = {
      Keys::Settings::LOCATION_ICON => "🌎",              # string emoji
      Keys::Settings::MEETING_LENGTH => "30m",            # ChronicDuration
      Keys::Settings::START_OF_DAY => "9am",              # BusinessTime
      Keys::Settings::END_OF_DAY => "6pm",                # BusinessTime
      Keys::Options::CALENDARS => [DEFAULT_CALENDAR_ID],  # array of calendar ids
      Keys::Options::COLOR => true,                       # bool
    }

    attr_reader :user_config, :options, :defaults

    def initialize(options: {},
                   user_config: {},
                   defaults: DEFAULT_SETTINGS)
      @defaults = defaults
      @options = options
      @user_config = user_config
    end

    def in_env(&block)
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

    def get(keypath)
      rval = Config.find_in_hash(user_config, keypath)

      if rval.is_a?(Hash)
        raise CalendarAssistant::Config::AccessingHashAsScalar, "keypath #{keypath} is not a scalar"
      end

      rval
    end

    def set(keypath, value)
      Config.set_in_hash user_config, keypath, value
    end

    #
    #  note that, despite the name, this method returns both options
    #  and settings
    #
    def setting(setting_name)
      context = Config.find_in_hash(options, Keys::Options::CONTEXT)
      Config.find_in_hash(options, setting_name) ||
        Config.find_in_hash(user_config, [Keys::SETTINGS, context, setting_name]) ||
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
    #  helper method for Keys::Options::CALENDARS
    #
    def calendar_ids
      split_if_array(Keys::Options::CALENDARS)
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

    def event_visibility
      value = setting(Keys::Settings::VISIBILITY)
      case value
      when CalendarAssistant::Event::Visibility::PUBLIC
        CalendarAssistant::Event::Visibility::PUBLIC
      when CalendarAssistant::Event::Visibility::PRIVATE
        CalendarAssistant::Event::Visibility::PRIVATE
      else
        CalendarAssistant::Event::Visibility::DEFAULT
      end
    end

    private

    def split_if_array(key)
      a = setting(key)
      if a.is_a?(String)
        a = a.split(",")
      end
      a
    end

    def self.find_in_hash(hash, keypath)
      split_keypath(keypath).inject(hash) do |current_val, key|
        break unless current_val.has_key?(key)
        current_val[key]
      end
    end

    def self.set_in_hash(hash, keypath, new_value)
      *path_parts, key = *split_keypath(keypath)

      current_hash = path_parts.inject(hash) do |current_val, path|
        current_val[path] ||= {}
      end

      current_hash[key] = new_value
    end

    def self.split_keypath(keypath)
      keypath.is_a?(Array) ? keypath : keypath.split(".")
    end
  end
end
