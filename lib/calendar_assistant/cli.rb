require "thor"
require "chronic"

class CalendarAssistant
  class Location < Thor
    desc "set <calendar-id> <datespec> <location>", "create an all-day event to declare your geographic location"
    def set calendar_id, datespec, location
      ca = CalendarAssistant.new calendar_id

      ca.create_geographic_event CalendarAssistant.time_or_time_range(datespec), location
    end

    desc "get <calendar-id> <datespec>", "display your geographic location for a date or range of dates"
    def get calendar_id, datespec
      ca = CalendarAssistant.new calendar_id

      events = ca.find_geographic_events CalendarAssistant.time_or_time_range(datespec)
      events.each do |event|
        puts event.to_assistant_s
      end
    end
  end

  class CLI < Thor
    desc "location <subcommand> ...args", "manage your location via all-day calendar events"
    subcommand "location", Location
  end
end
