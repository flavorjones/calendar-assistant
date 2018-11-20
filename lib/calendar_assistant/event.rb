class CalendarAssistant
  class Event < SimpleDelegator
    #
    #  constants describing enumerated attribute values
    #  see https://developers.google.com/calendar/v3/reference/events
    #
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

    #
    #  constants describing behavior
    #
    LOCATION_EVENT_REGEX = /^#{CalendarAssistant::EMOJI_WORLDMAP}/

    #
    #  methods
    #
    def update **args
      update!(**args)
      self
    end

    def location_event?
      !! (summary =~ LOCATION_EVENT_REGEX)
    end

    def all_day?
      !! (start.nil? ? self.end.to_date : start.to_date)
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
      response_status == CalendarAssistant::Event::Response::ACCEPTED
    end

    def declined?
      response_status == CalendarAssistant::Event::Response::DECLINED
    end

    def awaiting?
      response_status == CalendarAssistant::Event::Response::NEEDS_ACTION
    end

    def self?
      response_status == CalendarAssistant::Event::Response::SELF
    end

    def one_on_one?
      return false if attendees.nil?
      return false unless attendees.any? { |a| a.self }
      return false if human_attendees.length != 2
      true
    end

    def busy?
      transparency != CalendarAssistant::Event::Transparency::TRANSPARENT
    end

    def commitment?
      return false if human_attendees.nil? || human_attendees.length < 2
      return false if declined?
      true
    end

    def private?
      visibility == CalendarAssistant::Event::Visibility::PRIVATE
    end

    def public?
      visibility == CalendarAssistant::Event::Visibility::PUBLIC
    end

    def explicit_visibility?
      private? || public?
    end

    def start_time
      if all_day?
        start.to_date.beginning_of_day
      else
        start.date_time
      end
    end

    def start_date
      if all_day?
        start.to_date
      else
        start.date_time.to_date
      end
    end

    def end_time
      if all_day?
        self.end.to_date.beginning_of_day
      else
        self.end.date_time
      end
    end

    def end_date
      if all_day?
        self.end.to_date
      else
        self.end.date_time.to_date
      end
    end

    def view_summary
      return "(private)" if private? && (summary.nil? || summary.blank?)
      return "(no title)" if summary.nil? || summary.blank?
      summary
    end

    def duration
      if all_day?
        days = (self.end_date - start_date).to_i
        return "#{days}d"
      end

      p = ActiveSupport::Duration.build(self.end.date_time - start.date_time).parts
      s = []
      s << "#{p[:hours]}h" if p.has_key?(:hours)
      s << "#{p[:minutes]}m" if p.has_key?(:minutes)
      s.join(" ")
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
      return CalendarAssistant::Event::Response::SELF if attendees.nil?
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
end
