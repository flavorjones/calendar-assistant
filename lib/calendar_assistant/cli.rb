require "thor"
require "chronic"
require "launchy"

class CalendarAssistant
  class CLIHelpers
    def self.time_or_time_range userspec
      if userspec =~ /\.\.\./
        start_userspec, end_userspec = userspec.split("...")
        start_time = Chronic.parse(start_userspec.strip) || raise("could not parse #{start_userspec.strip}")
        end_time   = Chronic.parse(end_userspec.strip) || raise("could not parse #{end_userspec.strip}")
        return start_time..end_time
      end
      Chronic.parse(userspec) || raise("could not parse #{userspec}")
    end

    def self.now
      GCal::Event.new start: GCal::EventDateTime.new(date_time: Time.now),
                      end: GCal::EventDateTime.new(date_time: Time.now),
                      summary: Rainbow("          now          ").inverse.faint
    end

    class Out
      attr_reader :io

      def initialize io=STDOUT
        @io = io
      end

      def print_now! event, ca, options, printed_now
        return true if printed_now
        return false if event.all_day?
        return false if event.start_date != Date.today

        if event.start.date_time > Time.now
          io.puts ca.event_description(CLIHelpers.now, options)
          return true
        end

        false
      end

      def print_events ca, events, options={}
        if events.nil? || events.empty?
          io.puts "No events in this time range."
          return
        end

        display_events = events.select do |event|
          ! options[:commitments] || ca.event_attributes(event).include?(GCal::Event::Attributes::COMMITMENT)
        end

        printed_now = false
        display_events.each do |event|
          printed_now = print_now! event, ca, options, printed_now
          io.puts ca.event_description(event, options)
        end
      end

      def launch url
        Launchy.open url
      end

      def puts *args
        io.puts(*args)
      end
    end
  end

  class Location < Thor
    desc "show PROFILE_NAME [DATE | DATERANGE]",
         "show your location for a date or range of dates (default today)"
    def show calendar_id, datespec="today"
      ca = CalendarAssistant.new calendar_id
      events = ca.find_location_events CLIHelpers.time_or_time_range(datespec)
      CLIHelpers::Out.new.print_events ca, events, options
    end

    desc "set PROFILE_NAME LOCATION [DATE | DATERANGE]",
         "show your location for a date or range of dates (default today)"
    def set calendar_id, location, datespec="today"
      ca = CalendarAssistant.new calendar_id
      events = ca.create_location_event CLIHelpers.time_or_time_range(datespec), location
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
      events = ca.find_events CLIHelpers.time_or_time_range(datespec)
      CLIHelpers::Out.new.print_events ca, events, options
    end


    desc "join PROFILE_NAME",
         "join whatever video call is attached to your current meeting"
    option :print,
           type: :boolean,
           desc: "print the video call URL instead of launching it",
           aliases: ["-p"]
    def join calendar_id
      ca = CalendarAssistant.new calendar_id
      url = ca.find_current_av_url
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
