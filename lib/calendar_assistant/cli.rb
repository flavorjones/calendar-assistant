require "thor"
require "chronic"

class CalendarAssistant
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
      service = CalendarAssistant.authorize profile_name
      puts "\nYou're authorized!\n\n"

      puts 'Upcoming events:'
      response = service.list_events('primary', max_results: 10, single_events: true, order_by: 'startTime', time_min: Time.now.iso8601)
      if response.items.empty?
        puts '(No upcoming events found)'
      else
        response.items.each do |event|
          start = event.start.date || event.start.date_time
          puts "- #{event.summary} (#{start})"
        end
      end
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

    desc "get <calendar-id> <datespec>", "display your location for a date or range of dates"
    def get calendar_id, datespec
      ca = CalendarAssistant.new calendar_id

      events = ca.find_location_events CalendarAssistant.time_or_time_range(datespec)
      events.each do |event|
        puts event.to_assistant_s
        pp event.raw if options[:verbose]
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

    desc "location <subcommand> ...args", "manage your location via all-day calendar events"
    subcommand "location", Location
  end
end
