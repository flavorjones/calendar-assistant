class CalendarAssistant
  class EventRepository
    attr_reader :calendar, :calendar_id

    def initialize(service, calendar_id)
      @service = service
      @calendar_id = calendar_id
      @calendar = @service.get_calendar @calendar_id
    end

    def in_tz &block
      CalendarAssistant.in_tz calendar.time_zone do
        yield
      end
    end

    def find time_range
      events = @service.list_events(@calendar_id,
                                   time_min: time_range.first.iso8601,
                                   time_max: time_range.last.iso8601,
                                   order_by: "startTime",
                                   single_events: true,
                                   max_results: 2000,
                                   )
      if events.nil? || events.items.nil?
        return []
      end
      events.items.map { |e| CalendarAssistant::Event.new(e) }
    end

    def new event_attributes
      event = GCal::Event.new DateHelpers.cast_dates(event_attributes)
      CalendarAssistant::Event.new(event)
    end

    def create event_attributes
      new(event_attributes).tap do |event|
        @service.insert_event @calendar_id, event.__getobj__
      end
    end

    def delete event
      @service.delete_event @calendar_id,  event.id
    end

    def update(event, attributes)
      event.update! DateHelpers.cast_dates(attributes)
      updated_event = @service.update_event @calendar_id, event.id, event
      CalendarAssistant::Event.new(updated_event)
    end
  end
end
