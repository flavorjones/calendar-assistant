class CalendarAssistant
  class EventRepository
    def initialize(service, calendar_id)
      @service = service
      @calendar_id = calendar_id
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

    def create event_attributes
      event = GCal::Event.new cast_dates(event_attributes)
      @service.insert_event @calendar_id, event
      CalendarAssistant::Event.new(event)
    end

    def delete event
      @service.delete_event @calendar_id,  event.id
    end

    def update(event, attributes)
      event.update! cast_dates(attributes)
      updated_event = @service.update_event @calendar_id, event.id, event
      CalendarAssistant::Event.new(updated_event)
    end

    private

    def cast_dates attributes
      attributes.each_with_object({}) do |(key, value), object|
        if value.is_a?(Date)
          object[key] = GCal::EventDateTime.new(date: value.iso8601)
        else
          object[key] = value
        end
      end
    end
  end
end