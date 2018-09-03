require "thor"
require "chronic"

class CalendarAssistant
  class Helpers
    def self.time_or_time_range userspec
      if userspec =~ /\.\.\./
        start_userspec, end_userspec = userspec.split("...")
        start_time = Chronic.parse start_userspec.strip
        end_time   = Chronic.parse end_userspec.strip
        return start_time..end_time
      end
      Chronic.parse userspec
    end

    def self.print_events ca, events, options={}
      if events
        events.each do |event|
          puts ca.event_description event, verbose: options[:verbose]
        end
        puts "\n#{ITALIC_ON}(All times are in #{ca.calendar.time_zone})#{ITALIC_OFF}"
      else
        puts "No events in this time range."
      end
    end
  end

  class Location < Thor
    desc "show PROFILE_NAME [DATE | DATERANGE]", "show your location for a date or range of dates (default today)"
    def show calendar_id, datespec="today"
      ca = CalendarAssistant.new calendar_id
      events = ca.find_location_events Helpers.time_or_time_range(datespec)
      Helpers.print_events ca, events, verbose: options[:verbose]
    end
  end

  class CLI < Thor
    class_option :verbose, type: :boolean, desc: "print more information", aliases: ["-v"]

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

    desc "location SUBCOMMAND ...ARGS", "manage your location via all-day calendar events"
    subcommand "location", Location

    desc "show PROFILE_NAME [DATE | DATERANGE]", "show your events for a date or range of dates (default today)"
    def show calendar_id, datespec="today"
      ca = CalendarAssistant.new calendar_id
      events = ca.find_events Helpers.time_or_time_range(datespec)
      Helpers.print_events ca, events, verbose: options[:verbose]
    end
  end
end
