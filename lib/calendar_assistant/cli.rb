require "thor"
require "chronic"
require "launchy"

require "calendar_assistant/cli_helpers"

class CalendarAssistant
  class CLI < Thor
    #  note that these options are passed straight through to CLIHelpers.print_events
    class_option :verbose,
                 type: :boolean,
                 desc: "print more information",
                 aliases: ["-v"]
    class_option :debug,
                 type: :boolean,
                 desc: "how dare you suggest there are bugs",
                 aliases: ["-d"]


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


    desc "show PROFILE_NAME [DATE | DATERANGE | TIMERANGE]",
         "Show your events for a date or range of dates (default 'today')"
    option :commitments,
           type: :boolean,
           desc: "only show events that you've accepted with another person",
           aliases: ["-c"]
    def show calendar_id, datespec="today"
      ca = CalendarAssistant.new calendar_id
      events = ca.find_events CLIHelpers.parse_datespec(datespec)
      CLIHelpers::Out.new.print_events ca, events, options
    end


    desc "join PROFILE_NAME [TIME]",
         "Open the URL for a video call attached to your meeting at time TIME (default 'now')"
    option :print,
           type: :boolean,
           desc: "print the video call URL instead of opening it",
           aliases: ["-p"]
    def join calendar_id, timespec="now"
      ca = CalendarAssistant.new calendar_id
      event, url = CLIHelpers.find_av_uri ca, timespec
      if event
        CLIHelpers::Out.new.print_events ca, [event], options
        if options[:print]
          CLIHelpers::Out.new.puts url
        else
          CLIHelpers::Out.new.launch url
        end
      else
        CLIHelpers::Out.new.puts "Could not find a meeting '#{timespec}' with a video call to join."
      end
    end

    desc "location PROFILE_NAME [DATE | DATERANGE]",
         "Show your location for a date or range of dates (default 'today')"
    def location calendar_id, datespec="today"
      ca = CalendarAssistant.new calendar_id
      events = ca.find_location_events CLIHelpers.parse_datespec(datespec)
      CLIHelpers::Out.new.print_events ca, events, options
    end

    desc "location-set PROFILE_NAME LOCATION [DATE | DATERANGE]",
         "Set your location to LOCATION for a date or range of dates (default 'today')"
    def location_set calendar_id, location, datespec="today"
      ca = CalendarAssistant.new calendar_id
      events = ca.create_location_event CLIHelpers.parse_datespec(datespec), location
      events.keys.each do |key|
        puts Rainbow(key.capitalize).bold
        CLIHelpers::Out.new.print_events ca, events[key], options
      end
    end
  end
end
