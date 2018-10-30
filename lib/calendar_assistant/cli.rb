require "thor"
require "chronic"
require "chronic_duration"
require "launchy"

require "calendar_assistant/cli_helpers"

class CalendarAssistant
  class CLI < Thor
    def self.supports_profile_option
      option :profile,
             type: :string,
             desc: "the profile you'd like to use (if different from default)",
             aliases: ["-p"]
    end

    default_config = CalendarAssistant::Config.new options: options # used in option descriptions

    class_option :help,
                 type: :boolean,
                 aliases: ["-h", "-?"]
    class_option :debug,
                 type: :boolean,
                 desc: "how dare you suggest there are bugs"


    desc "config",
         "Dump your configuration parameters (merge of defaults and overrides from #{CalendarAssistant::Config::CONFIG_FILE_PATH})"
    def config
      return if handle_help_args
      config = CalendarAssistant::Config.new
      settings = {}
      setting_names = CalendarAssistant::Config::Keys::Settings.constants.map { |k| CalendarAssistant::Config::Keys::Settings.const_get k }
      setting_names.each do |key|
        settings[key] = config.setting key
      end
      puts TOML::Generator.new({CalendarAssistant::Config::Keys::SETTINGS => settings}).body
    end


    desc "setup",
         "Link your local calendar-assistant installation to a Google API Client"
    long_desc <<~EOD
      This command will walk you through setting up a Google Cloud
      Project, enabling the Google Calendar API, and saving the
      credentials necessary to access the API on behalf of users.

      If you already have downloaded client credentials, you don't
      need to run this command. Instead, rename the downloaded JSON
      file to `#{CalendarAssistant::Authorizer::CREDENTIALS_PATH}`
    EOD
    def setup
      out = CLIHelpers::Out.new
      if File.exist? CalendarAssistant::Authorizer::CREDENTIALS_PATH
        out.puts sprintf("Credentials already exist in %s",
                         CalendarAssistant::Authorizer::CREDENTIALS_PATH)
        exit 0
      end

      out.launch "https://developers.google.com/calendar/quickstart/ruby"
      sleep 1
      out.puts <<~EOT
        Please click on "ENABLE THE GOOGLE CALENDAR API" and either create a new project or select an existing project.

        (If you create a new project, name it something like "yourname-calendar-assistant" so you remember why it exists.)

        Then click "DOWNLOAD CLIENT CONFIGURATION" to download the credentials to local disk.

        Finally, paste the contents of the downloaded file here (it should be a complete JSON object):
      EOT

      json = out.prompt "Paste JSON here"
      File.open(CalendarAssistant::Authorizer::CREDENTIALS_PATH, "w") do |f|
        f.write json
      end
      FileUtils.chmod 0600, CalendarAssistant::Authorizer::CREDENTIALS_PATH

      out.puts "\nOK! Your next step is to run `calendar-assistant authorize`."
    end


    desc "authorize PROFILE_NAME",
         "create (or validate) a profile named NAME with calendar access"
    long_desc <<~EOD
      Create and authorize a named profile (e.g., "work", "home",
      "flastname@company.tld") to access your calendar.

      When setting up a profile, you'll be asked to visit a URL to
      authenticate, grant authorization, and generate and persist an
      access token.

      In order for this to work, you'll need to have set up your API client
      credentials. Run `calendar-assistant help setup` for instructions.
    EOD
    def authorize profile_name
      return if handle_help_args
      CalendarAssistant.authorize profile_name
      puts "\nYou're authorized!\n\n"
    end


    desc "show [DATE | DATERANGE | TIMERANGE]",
         "Show your events for a date or range of dates (default 'today')"
    option :commitments,
           type: :boolean,
           desc: "only show events that you've accepted with another person",
           aliases: ["-c"]
    supports_profile_option
    def show datespec="today"
      return if handle_help_args
      config = CalendarAssistant::Config.new options: options
      ca = CalendarAssistant.new config
      events = ca.find_events CLIHelpers.parse_datespec(datespec)
      CLIHelpers::Out.new.print_events ca, events, options
    end


    desc "join [TIME]",
         "Open the URL for a video call attached to your meeting at time TIME (default 'now')"
    option :join,
           type: :boolean, default: true,
           desc: "launch a browser to join the video call URL"
    supports_profile_option
    def join timespec="now"
      return if handle_help_args
      config = CalendarAssistant::Config.new options: options
      ca = CalendarAssistant.new config
      event, url = CLIHelpers.find_av_uri ca, timespec
      if event
        CLIHelpers::Out.new.print_events ca, event, options
        CLIHelpers::Out.new.puts url
        if options[:join]
          CLIHelpers::Out.new.launch url
        end
      else
        CLIHelpers::Out.new.puts "Could not find a meeting '#{timespec}' with a video call to join."
      end
    end


    desc "location [DATE | DATERANGE]",
         "Show your location for a date or range of dates (default 'today')"
    supports_profile_option
    def location datespec="today"
      return if handle_help_args
      config = CalendarAssistant::Config.new options: options
      ca = CalendarAssistant.new config
      events = ca.find_location_events CLIHelpers.parse_datespec(datespec)
      CLIHelpers::Out.new.print_events ca, events, options
    end


    desc "location-set LOCATION [DATE | DATERANGE]",
         "Set your location to LOCATION for a date or range of dates (default 'today')"
    supports_profile_option
    def location_set location, datespec="today"
      return if handle_help_args
      config = CalendarAssistant::Config.new options: options
      ca = CalendarAssistant.new config
      events = ca.create_location_event CLIHelpers.parse_datespec(datespec), location
      CLIHelpers::Out.new.print_events ca, events, options
    end


    desc "availability [DATE | DATERANGE | TIMERANGE]",
         "Show your availability for a date or range of dates (default 'today')"
    option CalendarAssistant::Config::Keys::Settings::MEETING_LENGTH,
           type: :string,
           banner: "LENGTH",
           desc: sprintf("[default %s] find chunks of available time at least as long as LENGTH (which is a ChronicDuration string like '30m' or '2h')",
                         default_config.setting(CalendarAssistant::Config::Keys::Settings::MEETING_LENGTH)),
           aliases: ["-l"]
    option CalendarAssistant::Config::Keys::Settings::START_OF_DAY,
           type: :string,
           banner: "TIME",
           desc: sprintf("[default %s] find chunks of available time after TIME (which is a Chronic string like '9am' or '14:30')",
                         default_config.setting(CalendarAssistant::Config::Keys::Settings::START_OF_DAY)),
           aliases: ["-s"]
    option CalendarAssistant::Config::Keys::Settings::END_OF_DAY,
           type: :string,
           banner: "TIME",
           desc: sprintf("[default %s] find chunks of available time before TIME (which is a Chronic string like '9am' or '14:30')",
                         default_config.setting(CalendarAssistant::Config::Keys::Settings::END_OF_DAY)),
           aliases: ["-e"]
    supports_profile_option
    def availability datespec="today"
      return if handle_help_args
      config = CalendarAssistant::Config.new options: options
      ca = CalendarAssistant.new config
      events = ca.availability CLIHelpers.parse_datespec(datespec)
      CLIHelpers::Out.new.print_available_blocks ca, events, options
    end

    private

    def handle_help_args
      if options[:help]
        help(current_command_chain.first)
        return true
      end
    end
  end
end
