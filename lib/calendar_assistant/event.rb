class CalendarAssistant
  class Event < SimpleDelegator
    include HasDuration

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

    PREDICATES = {
      "response": %I[
        accepted?
        declined?
        awaiting?
        tentative?
      ],
      "temporal": %I[
        all_day?
        past?
        current?
        future?
      ],
      "visibility": %I[
        private?
        public?
        explicitly_visible?
        visible_guestlist?
      ],
      "attributes": %I[
        location_event?
        self?
        one_on_one?
        busy?
        commitment?
        recurring?
        abandoned?
        anyone_can_add_self?
        attendees_omitted?
        end_time_unspecified?
        guests_can_invite_others?
        guests_can_modify?
        guests_can_see_other_guests?
        private_copy?
        locked?
        needs_action?
      ],
    }

    #
    #  class methods
    #

    def self.location_event_prefix(config)
      icon = config[CalendarAssistant::Config::Keys::Settings::LOCATION_ICON]
      if nickname = config[CalendarAssistant::Config::Keys::Settings::NICKNAME]
        return "#{icon} #{nickname} @ "
      end
      "#{icon} "
    end

    #
    #  instance methods
    #
    def initialize(obj, config: CalendarAssistant::Config.new)
      super(obj)
      @config = config
    end

    def update(**args)
      update!(**args)
      self
    end

    def location_event?
      !!summary.try(:starts_with?, Event.location_event_prefix(@config))
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

    alias_method :needs_action?, :awaiting?

    def tentative?
      response_status == CalendarAssistant::Event::Response::TENTATIVE
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

    def explicitly_visible?
      private? || public?
    end

    def recurring?
      !!recurring_event_id
    end

    def abandoned?
      return false if declined? || self? || response_status.nil? || !visible_guestlist?
      human_attendees.each do |attendee|
        next if attendee.self
        return false if attendee.response_status != CalendarAssistant::Event::Response::DECLINED
      end
      return true
    end

    def visible_guestlist?
      gcsog = guests_can_see_other_guests?
      gcsog.nil? ? true : !!gcsog
    end

    def other_human_attendees
      return nil if attendees.nil?
      attendees.select { |a| !a.resource && !a.self }
    end

    def human_attendees
      return nil if attendees.nil?
      attendees.select { |a| !a.resource }
    end

    def attendee(id)
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
        if conference_data && conference_data.conference_solution.name == "Zoom Meeting"
          return conference_data.entry_points.detect{|d| d.entry_point_type == "video" }.uri
        end

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
