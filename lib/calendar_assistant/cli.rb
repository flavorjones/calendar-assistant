require "thor"
require "chronic"
require "launchy"

require "calendar_assistant/cli_helpers"

class CalendarAssistant
  class CLI < Thor
    #  note that these options are passed straight through to CLIHelpers.print_events
    class_option :profile,
                 type: :string,
                 desc: "the profile you'd like to use (if different from default)",
                 aliases: ["-p"]
    class_option :debug,
                 type: :boolean,
                 desc: "how dare you suggest there are bugs"


    desc "authorize PROFILE_NAME",
         "create (or validate) a profile named NAME with calendar access"
    long_desc <<~EOD
      Create and authorize a named profile (e.g., "work", "home",
      "flastname@company.tld") to access your calendar.

      When setting up a profile, you'll be asked to visit a URL to
      authenticate, grant authorization, and generate and persist an
      access token.

      In order for this to work, you'll need to follow the
      instructions at this URL first:

      > https://developers.google.com/calendar/quickstart/ruby

      Namely, the prerequisites are:
      \x5 1. Turn on the Google API for your account
      \x5 2. Create a new Google API Project
      \x5 3. Download the configuration file for the Project, and name it as `credentials.json`
    EOD
    def authorize profile_name
      CalendarAssistant.authorize profile_name
      puts "\nYou're authorized!\n\n"
    end


    desc "show [DATE | DATERANGE | TIMERANGE]",
         "Show your events for a date or range of dates (default 'today')"
    option :commitments,
           type: :boolean,
           desc: "only show events that you've accepted with another person",
           aliases: ["-c"]
    def show datespec="today"
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
    def join timespec="now"
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
    def location datespec="today"
      config = CalendarAssistant::Config.new options: options
      ca = CalendarAssistant.new config
      events = ca.find_location_events CLIHelpers.parse_datespec(datespec)
      CLIHelpers::Out.new.print_events ca, events, options
    end


    desc "location-set LOCATION [DATE | DATERANGE]",
         "Set your location to LOCATION for a date or range of dates (default 'today')"
    def location_set location, datespec="today"
      config = CalendarAssistant::Config.new options: options
      ca = CalendarAssistant.new config
      events = ca.create_location_event CLIHelpers.parse_datespec(datespec), location
      CLIHelpers::Out.new.print_events ca, events, options
    end

    desc "availability [DATE | DATERANGE | TIMERANGE]",
         "Show your availability for a date or range of dates (default 'today')"
    option :duration,
           type: :string,
           desc: "find chunks of available time at least as long as DURATION",
           aliases: ["-d"]
    def availability datespec="today"
      config = CalendarAssistant::Config.new options: options
      ca = CalendarAssistant.new config
      events = ca.availability CLIHelpers.parse_datespec(datespec)
      CLIHelpers::Out.new.print_available_blocks ca, events, options
    end
  end
end
