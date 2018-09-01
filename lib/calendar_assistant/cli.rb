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

    def self.print_events ca, events
      puts "#{ITALIC_ON}(All times are in #{ca.calendar.time_zone})#{ITALIC_OFF}"
      events.each do |event|
        puts ca.event_description event
      end if events
    end
  end

  class Location < Thor
    desc "show PROFILE_NAME [DATE | DATERANGE]", "show your location for a date or range of dates"
    def show calendar_id, datespec="today"
      ca = CalendarAssistant.new calendar_id
      events = ca.find_location_events Helpers.time_or_time_range(datespec)
      Helpers.print_events ca, events
    end
  end

  class CLI < Thor
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

    desc "show PROFILE_NAME [DATE | DATERANGE]", "show your events for a date or range of dates"
    def show calendar_id, datespec="today"
      ca = CalendarAssistant.new calendar_id
      events = ca.find_events Helpers.time_or_time_range(datespec)
      Helpers.print_events ca, events
    end
  end
end


class OldCalendarAssistant
  class Location < Thor
    desc "set <calendar-id> <datespec> <location>", "create an all-day event to declare your location"
    def set calendar_id, datespec, location
      ca = CalendarAssistant.new calendar_id

      response = ca.create_location_event CalendarAssistant.time_or_time_range(datespec), location

      if response[:deleted]
        puts "Deleted:"
        response[:deleted].each do |event|
          puts event.to_assistant_s
          puts event.raw if options[:verbose]
        end
      end

      if response[:modified]
        puts "Modified:"
        response[:modified].each do |event|
          puts event.to_assistant_s
          puts event.raw if options[:verbose]
        end
      end

      if response[:created]
        puts "Created:"
        response[:created].each do |event|
          puts event.to_assistant_s
          puts event.raw if options[:verbose]
        end
      end
    end
  end

  class CLI < Thor
    class_option :verbose, type: :boolean, aliases: [:v]

    desc "get <calendar-id> <datespec>", "display events for a date or range of dates"
    def get calendar_id, datespec
      ca = CalendarAssistant.new calendar_id

      events = ca.find_events CalendarAssistant.time_or_time_range(datespec)
      events.each do |event|
        puts event.to_assistant_s
        pp event.raw if options[:verbose]
      end
    end
  end
end
