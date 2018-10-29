#
#  this file extends the Google::Event class found in the "google_calendar" rubygem
#

require "google/apis/calendar_v3"
require "time"
require "calendar_assistant/extensions/event_date_time_extensions"

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

  def update **args
    # this should be in the google API classes, IMHO
    update!(**args)
    self
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
                  description_link = CalendarAssistant::StringHelpers.find_uri_for_domain(description, "zoom.us")
                  return description_link if description_link

                  location_link = CalendarAssistant::StringHelpers.find_uri_for_domain(location, "zoom.us")
                  return location_link if location_link

                  return hangout_link if hangout_link
                  nil
                end
  end
end