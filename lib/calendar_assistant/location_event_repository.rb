class CalendarAssistant
  class LocationEventRepository < EventRepository
    def find(time, predicates: {})
      event_set = super time, predicates: predicates
      event_set.new event_set.events.select { |e| e.location_event? }
    end

    def create(time, location, predicates: {})
      # find pre-existing events that overlap
      existing_event_set = find time, predicates: predicates

      # augment event end date appropriately
      range = CalendarAssistant.date_range_cast time

      event = super(
        transparency: CalendarAssistant::Event::Transparency::TRANSPARENT,
        start: range.first, end: range.last,
        summary: "#{Event.location_event_prefix(@config)}#{location}",
      )

      modify_location_events(event, existing_event_set)
    end

    private

    def modify_location_events(event, existing_event_set)
      response = existing_event_set.new({ created: [event] })

      existing_event_set.events.each do |existing_event|
        if event.cover?(existing_event)
          response[:deleted] << delete(existing_event)
        elsif event.overlaps_start_of?(existing_event)
          response[:modified] << update(existing_event, start: event.end_date)
        elsif event.overlaps_end_of?(existing_event)
          response[:modified] << update(existing_event, end: event.start_date)
        end
      end

      response
    end
  end
end
