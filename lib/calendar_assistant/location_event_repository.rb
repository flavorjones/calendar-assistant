class CalendarAssistant
  class LocationEventRepository < EventRepository
    def find time, predicates: {}
      event_set = super time, predicates: predicates
      event_set.new event_set.events.select { |e| e.location_event? }
    end

    def create time, location, predicates: {}
      # find pre-existing events that overlap
      existing_event_set = find time, predicates: predicates

      # augment event end date appropriately
      range = CalendarAssistant.date_range_cast time

      deleted_events = []
      modified_events = []

      event = super(
          transparency: CalendarAssistant::Event::Transparency::TRANSPARENT,
          start: range.first, end: range.last,
          summary: "#{Event.location_event_prefix(@config)}#{location}"
      )

      existing_event_set.events.each do |existing_event|
        if existing_event.start_date >= event.start_date && existing_event.end_date <= event.end_date
          delete existing_event
          deleted_events << existing_event
        elsif existing_event.start_date <= event.end_date && existing_event.end_date > event.end_date
          update existing_event, start: range.last
          modified_events << existing_event
        elsif existing_event.start_date < event.start_date && existing_event.end_date >= event.start_date
          update existing_event, end: range.first
          modified_events << existing_event
        end
      end

      response = {created: [event]}
      response[:deleted] = deleted_events unless deleted_events.empty?
      response[:modified] = modified_events unless modified_events.empty?

      existing_event_set.new response
    end
  end
end
