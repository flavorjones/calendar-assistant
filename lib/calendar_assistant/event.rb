class CalendarAssistant
  class Event < SimpleDelegator

    LOCATION_EVENT_REGEX = /^#{CalendarAssistant::EMOJI_WORLDMAP}/

    def update **args
      super
      self
    end

    def location_event?
      !! (summary =~ LOCATION_EVENT_REGEX)
    end

    def all_day?
      !! start.to_date
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
      response_status == GCal::Event::Response::ACCEPTED
    end

    def declined?
      response_status == GCal::Event::Response::DECLINED
    end

    def awaiting?
      response_status == GCal::Event::Response::NEEDS_ACTION
    end

    def one_on_one?
      return false if attendees.nil?
      return false unless attendees.any? { |a| a.self }
      return false if human_attendees.length != 2
      true
    end

    def busy?
      transparency != GCal::Event::Transparency::TRANSPARENT
    end

    def commitment?
      return false if human_attendees.nil? || human_attendees.length < 2
      return false if declined?
      true
    end

    def private?
      visibility == GCal::Event::Visibility::PRIVATE
    end

    def public?
      visibility == GCal::Event::Visibility::PUBLIC
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

    def view_summary
      return "(private)" if private? && (summary.nil? || summary.blank?)
      return "(no title)" if summary.nil? || summary.blank?
      summary
    end
  end
end
