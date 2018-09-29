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
    ONE_ON_ONE = "1:1"
  end

  TRANSPARENCY_NOT_BUSY = "transparent"
  TRANSPARENCY_BUSY = "opaque"

  LOCATION_EVENT_REGEX = /^#{CalendarAssistant::EMOJI_WORLDMAP}/

  def location_event?
    !! (summary =~ LOCATION_EVENT_REGEX)
  end

  def all_day?
    !! @start.to_date
  end

  def past?
    if all_day?
      Date.today >= self.end.to_date
    else
      self.end.date_time < Time.now
    end
  end

  def current?
    if all_day?
      self.start.to_date <= Date.today && Date.today < self.end.to_date
    else
      self.start.date_time <= Time.now && Time.now <= self.end.date_time
    end
  end

  def future?
    !past? && !current?
  end

  def start_date
    if all_day?
      self.start.to_date
    else
      self.start.date_time.to_date
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

  def response_status ca
    return Attributes::SELF if attendees.nil?
    attendee(ca.calendar.id).tap do |attendee|
      return attendee.response_status if attendee&.response_status
    end
  end

  def declined? ca
    response_status(ca) == Attributes::DECLINED
  end

  def av_uri
    @av_uri ||= begin
                  zoom = CalendarAssistant::StringHelpers.find_uri_for_domain(description, "zoom.us")
                  return zoom if zoom

                  return hangout_link if hangout_link
                  nil
                end
  end
end

class Google::Apis::CalendarV3::EventDateTime
  def to_date
    return nil if @date.nil?
    return Date.parse(@date) if @date.is_a?(String)
    @date
  end

  def to_s
    return @date.to_s if @date
    @date_time.strftime "%Y-%m-%d %H:%M"
  end
end
