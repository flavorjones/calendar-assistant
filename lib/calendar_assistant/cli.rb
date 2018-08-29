require "thor"
require "chronic"

class CalendarAssistant
  class CLI < Thor
    desc "where <calendar-id> <datespec> <location>", "create an all-day event to declare your geographic location"
    def where calendar_id, datespec, location
      ca = CalendarAssistant.new calendar_id

      if datespec =~ /\.\.\./
        start_datespec, end_datespec = datespec.split("...")
        start_date = Chronic.parse start_datespec.strip
        end_date = Chronic.parse end_datespec.strip
        ca.create_geographic_event start_date..end_date, location
      else
        ca.create_geographic_event Chronic.parse(datespec), location
      end
    end
  end
end
