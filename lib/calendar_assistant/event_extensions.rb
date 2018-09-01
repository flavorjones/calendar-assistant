#
#  this file extends the Google::Event class found in the "google_calendar" rubygem
#

require "google/apis/calendar_v3"
require "time"

class Google::Apis::CalendarV3::Event
  RESPONSE_DECLINED = "declined"
  RESPONSE_ACCEPTED = "accepted"
  RESPONSE_NEEDS_ACTION = "needsAction"

  def location_event?
    summary =~ /^#{CalendarAssistant::EMOJI_WORLDMAP}/
  end

  def all_day?
    @start.date
  end

  def attendee id
    attendees&.find do |attendee|
      attendee.email == id
    end
  end
end

class Google::Apis::CalendarV3::EventDateTime
  def to_s
    return @date.to_s if @date
    @date_time.strftime "%Y-%m-%d %H:%M"
  end
end

module Google
  class Event
    def to_assistant_s
      if assistant_location_event?
        if Event.parse_time(end_time) - Event.parse_time(start_time) <= 1.day
          sprintf "%-23.23s |                         | %-40.40s",
                  Event.assistant_date(Event.parse_time(start_time)), title
        else
          sprintf "%-23.23s | %-23.23s | %-40.40s",
                  Event.assistant_date(Event.parse_time(start_time)),
                  Event.assistant_date(Event.parse_time(end_time) - 1.day), title
        end
      else
        sprintf "%23.23s | %23.23s | %-40.40s",
                Event.assistant_time(Event.parse_time(start_time)),
                Event.assistant_time(Event.parse_time(end_time)), title
      end
    end

    private

    def self.assistant_time t
      t.getlocal.strftime("%Y-%m-%d %H:%M:%S %Z")      
    end

    def self.assistant_date t
      t.getlocal.strftime("%Y-%m-%d %a")
    end
  end
end
