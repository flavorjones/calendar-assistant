#
#  this file extends the Google::Event class found in the "google_calendar" rubygem
#

require "google/apis/calendar_v3"
require "time"

class Google::Apis::CalendarV3::Event
  module RealResponse
    DECLINED = "declined"
    ACCEPTED = "accepted"
    NEEDS_ACTION = "needsAction"
    TENTATIVE = "tentative"
  end

  module Response
    include RealResponse
    SELF = "self" # not part of Google's API, but useful to represent meetings-for-myself
  end

  module Transparency
    TRANSPARENT = "transparent"
    OPAQUE = "opaque"
  end

  module Visibility
    DEFAULT = "default"
    PUBLIC = "public"
    PRIVATE = "private"
  end

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

  def accepted?
    response_status == Response::ACCEPTED
  end

  def declined?
    response_status == Response::DECLINED
  end

  def one_on_one?
    return false if attendees.nil?
    return false unless attendees.any? { |a| a.self }
    return false if human_attendees.length != 2
    true
  end

  def busy?
    transparency != Transparency::TRANSPARENT
  end

  def commitment?
    return false if human_attendees.nil? || human_attendees.length < 2
    return false if declined?
    true
  end

  def private?
    visibility == Visibility::PRIVATE
  end

  def start_time
    if all_day?
      self.start.to_date.beginning_of_day
    else
      self.start.date_time
    end
  end

  def start_date
    if all_day?
      self.start.to_date
    else
      self.start.date_time.to_date
    end
  end

  def human_attendees
    return nil if attendees.nil?
    attendees.select { |a| ! a.resource }
  end

  def attendee id
    return nil if attendees.nil?
    attendees.find do |attendee|
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

  def av_uri
    @av_uri ||= begin
                  zoom = CalendarAssistant::StringHelpers.find_uri_for_domain(description, "zoom.us")
                  return zoom if zoom

                  return hangout_link if hangout_link
                  nil
                end
  end

  def view_summary
    return "(private)" if private? && (summary.nil? || summary.blank?)
    return "(no title)" if summary.nil? || summary.blank?
    summary
  end
end

class Google::Apis::CalendarV3::EventDateTime
  def to_date
    return nil if @date.nil?
    return Date.parse(@date) if @date.is_a?(String)
    @date
  end

  def to_date!
    return @date_time.to_date if @date.nil?
    to_date
  end

  def to_s
    return @date.to_s if @date
    @date_time.strftime "%Y-%m-%d %H:%M"
  end
end
