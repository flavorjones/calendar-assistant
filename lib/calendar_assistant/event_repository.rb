class CalendarAssistant
  class EventRepository
    attr_reader :calendar, :calendar_id, :config

    def initialize(service, calendar_id, config: CalendarAssistant::Config.new)
      @service = service
      @config = config
      @calendar_id = calendar_id
      @calendar = @service.get_calendar @calendar_id
    rescue Google::Apis::ClientError => e
      raise BaseException, "Calendar for #{@calendar_id} not found" if e.status_code == 404
      raise
    end

    def in_tz &block
      CalendarAssistant.in_tz calendar.time_zone do
        yield
      end
    end

    def find time_range, predicates: {}
      events = @service.list_events(@calendar_id,
                                   time_min: time_range.first.iso8601,
                                   time_max: time_range.last.iso8601,
                                   order_by: "startTime",
                                   single_events: true,
                                   max_results: 2000,
                                   )
      events = events.items.map { |e| CalendarAssistant::Event.new(e, config: config) }

      events = filter_by_predicates(events, predicates) unless predicates.empty?
      CalendarAssistant::EventSet.new self, events
    end

    def new event_attributes
      event = Google::Apis::CalendarV3::Event.new DateHelpers.cast_dates(event_attributes)
      event.visibility ||= config.event_visibility
      CalendarAssistant::Event.new(event, config: config)
    end

    def create event_attributes
      new(event_attributes).tap do |event|
        @service.insert_event @calendar_id, event.__getobj__
      end
    end

    def delete event
      @service.delete_event @calendar_id,  event.id
      event
    end

    def update(event, attributes)
      event.update! DateHelpers.cast_dates(attributes)
      updated_event = @service.update_event @calendar_id, event.id, event
      CalendarAssistant::Event.new(updated_event, config: config)
    end

    def available_block start_time, end_time
      e = Google::Apis::CalendarV3::Event.new(
        start: Google::Apis::CalendarV3::EventDateTime.new(date_time: start_time.in_time_zone(calendar.time_zone).to_datetime),
        end: Google::Apis::CalendarV3::EventDateTime.new(date_time: end_time.in_time_zone(calendar.time_zone).to_datetime),
        summary: "available"
      )
      CalendarAssistant::Event.new e, config: config
    end

    private

    def filter_by_predicates(events, predicates)
      valid_predicates = CalendarAssistant::Event::PREDICATES.values.flatten

      events.select do |event|
        predicates.all? do |predicate, value|
          raise BaseException, "Invalid event predicate" unless valid_predicates.include?(predicate)
          event.public_send(predicate) == value
        end
      end
    end
  end
end
