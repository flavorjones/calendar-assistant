require "thor"
require "chronic"
require "launchy"

require "calendar_assistant/cli_helpers"

class CalendarAssistant
  class Location < Thor
    desc "show PROFILE_NAME [DATE | DATERANGE]",
         "show your location for a date or range of dates (default today)"
    def show calendar_id, datespec="today"
      ca = CalendarAssistant.new calendar_id
      events = ca.find_location_events CLIHelpers.parse_datespec(datespec)
      CLIHelpers::Out.new.print_events ca, events, options
    end

    desc "set PROFILE_NAME LOCATION [DATE | DATERANGE]",
         "show your location for a date or range of dates (default today)"
    def set calendar_id, location, datespec="today"
      ca = CalendarAssistant.new calendar_id
      events = ca.create_location_event CLIHelpers.parse_datespec(datespec), location
      events.keys.each do |key|
        puts Rainbow(key.capitalize).bold
        CLIHelpers::Out.new.print_events ca, events[key], options
      end
    end
  end

  class CLI < Thor
    #
    # options
    # note that these options are passed straight through to CLIHelpers.print_events
    #
    class_option :verbose,
                 type: :boolean,
                 desc: "print more information",
                 aliases: ["-v"]
    class_option :commitments,
                 type: :boolean,
                 desc: "only show events that you've accepted with another person",
                 aliases: ["-c"]
    class_option :debug,
                 type: :boolean,
                 desc: "how dare you suggest there are bugs",
                 aliases: ["-d"]


    desc 'authorize PROFILE_NAME', 'create (or validate) a named profile with calendar access'
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

      (1) Turn on the Google API for your account
      \x5(2) Create a new Google API Project
      \x5(3) Download the configuration file for the Project, and name it as `credentials.json`
    EOD
    def authorize profile_name
      CalendarAssistant.authorize profile_name
      puts "\nYou're authorized!\n\n"
    end


    desc "show PROFILE_NAME [DATE | DATERANGE]",
         "show your events for a date or range of dates (default today)"
    def show calendar_id, datespec="today"
      ca = CalendarAssistant.new calendar_id
      events = ca.find_events CLIHelpers.parse_datespec(datespec)
      CLIHelpers::Out.new.print_events ca, events, options
    end


    desc "join PROFILE_NAME [TIME]",
         "join whatever video call is attached to meeting (default to 'now' for current meetings)"
    option :print,
           type: :boolean,
           desc: "print the video call URL instead of launching it",
           aliases: ["-p"]
    def join calendar_id, timespec="now"
      ca = CalendarAssistant.new calendar_id
      url = CLIHelpers.find_av_uri ca, timespec
      if url
        if options[:print]
          CLIHelpers::Out.new.puts url
        else
          CLIHelpers::Out.new.launch url
        end
      else
        CLIHelpers::Out.new.puts "Could not find a current meeting with a video call to join."
      end
    end

    desc "location SUBCOMMAND ...ARGS",
         "manage your location via all-day calendar events"
    subcommand "location", Location
  end
end
