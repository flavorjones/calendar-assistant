#
#  this file extends the Google::Event class found in the "google_calendar" rubygem
#

require "google/apis/calendar_v3"
require "time"

class Google::Apis::CalendarV3::Event
  module Response
    DECLINED = "declined"
    ACCEPTED = "accepted"
    NEEDS_ACTION = "needsAction"
    TENTATIVE = "tentative"
    SELF = "self" # not part of Google's API, but useful to represent meetings-for-myself
  end

  module Attribute
    DECLINED = Response::DECLINED
    ACCEPTED = Response::ACCEPTED
    NEEDS_ACTION = Response::NEEDS_ACTION
    TENTATIVE = Response::TENTATIVE
    SELF = Response::SELF
    RECURRING = "recurring"
    COMMITMENT = "commitment"
    ONE_ON_ONE = "1:1"
  end

  TRANSPARENCY_NOT_BUSY = "transparent"
  TRANSPARENCY_BUSY = "opaque"

  LOCATION_EVENT_REGEX = /^#{CalendarAssistant::EMOJI_WORLDMAP}/

  def update **args
    # this should be in the google API classes, IMHO
    update!(**args)
    self
  end

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
      Time.now >= self.end.date_time
    end
  end

  def current?
    ! (past? || future?)
  end

  def future?
    if all_day?
      self.start.to_date > Date.today
    else
      self.start.date_time > Time.now
    end
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

  def response_status
    return Response::SELF if attendees.nil?
    attendees.each do |attendee|
      return attendee.response_status if attendee.self
    end
    nil
  end

  def declined?
    response_status == Attribute::DECLINED
  end

  def av_uri
    @av_uri ||= begin
                  zoom = CalendarAssistant::StringHelpers.find_uri_for_domain(description, "zoom.us")
                  return zoom if zoom

                  return hangout_link if hangout_link
                  nil
                end
  end

  #
  #  untested below here
  #
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
