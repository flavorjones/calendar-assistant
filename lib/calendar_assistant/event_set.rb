class CalendarAssistant
  class EventSet
    attr_reader :event_repository, :events

    def initialize event_repository, events=nil
      @event_repository = event_repository
      @events = events
    end

    def empty?
      return true if events.nil?
      if events.is_a?(Enumerable)
        return events.length == 0
      end
      false
    end

    def == rhs
      return false unless rhs.is_a?(EventSet)
      self.event_repository == rhs.event_repository && self.events == rhs.events
    end

    def new new_events
      self.class.new self.event_repository, new_events
    end
  end
end
