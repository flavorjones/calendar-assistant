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
      events.items
    end
  end
end