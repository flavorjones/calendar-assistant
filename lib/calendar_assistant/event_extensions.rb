#
#  this file extends the Google::Event class found in the "google_calendar" rubygem
#

require "google/apis/calendar_v3"
require "time"

class Google::Apis::CalendarV3::Event
  RESPONSE_DECLINED = "declined"
  RESPONSE_ACCEPTED = "accepted"
  RESPONSE_NEEDS_ACTION = "needsAction"
  RESPONSE_TENTATIVE = "tentative"

  module Attributes
    DECLINED = RESPONSE_DECLINED
    ACCEPTED = RESPONSE_ACCEPTED
    NEEDS_ACTION = RESPONSE_NEEDS_ACTION
    TENTATIVE = RESPONSE_TENTATIVE
    RECURRING = "recurring"
    SELF = "self"
    COMMITMENT = "commitment"
  end

  TRANSPARENCY_NOT_BUSY = "transparent"
  TRANSPARENCY_BUSY = "opaque"

  def location_event?
    summary =~ /^#{CalendarAssistant::EMOJI_WORLDMAP}/
  end

  def all_day?
    @start.date
  end

  def past?
    if all_day?
      self.end.date < Date.today
    else
      self.end.date_time < Time.now
    end
  end

  def current?
    if all_day?
      Date.parse(self.start.date) <= Date.today && Date.today <= Date.parse(self.end.date)
    else
      self.start.date_time <= Time.now && Time.now <= self.end.date_time
    end
  end

  def attendee id
    attendees&.find do |attendee|
      attendee.email == id
    end
  end

  def recurrence_rules service
    recurrence(service).grep(/RRULE/).join("\n")
  end

  def recurrence service=nil
    if recurring_event_id
      recurrence_parent(service)&.recurrence
    else
      @recurrence
    end
  end

  def recurrence_parent service
    @recurrence_parent ||= if recurring_event_id
                             service.get_event CalendarAssistant::DEFAULT_CALENDAR_ID, recurring_event_id
                           else
                             nil
                           end
  end
end

class Google::Apis::CalendarV3::EventDateTime
  def to_s
    return @date.to_s if @date
    @date_time.strftime "%Y-%m-%d %H:%M"
  end
end
