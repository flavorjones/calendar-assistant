class CalendarAssistant
  class LocalService
    Result = Struct.new(:items)
    attr_reader :file

    def initialize(file: nil, load_events: true)
      @file = file
      if (@file && File.exist?(@file) && load_events)
        payload = File.read(@file)
        @store = if YAML.respond_to?(:unsafe_load)
          YAML::unsafe_load(payload)
        else
          YAML::load(payload)
        end
      else
        @store = {}
      end
    end

    def list_events(calendar_id, options)
      time_min = Time.parse(options.fetch(:time_min))
      time_max = Time.parse(options.fetch(:time_max))
      search_range = time_min..time_max

      events = get_calendar_events(calendar_id).map do |id, event|
        event_range = (event.start.date_time || event.start.date)..(event.end.date_time || event.end.date)
        event if (event_range.first < search_range.last && event_range.last > search_range.first)
      end.compact
      Result.new(events)
    end

    def insert_event(calendar_id, event)
      save do
        get_calendar_events(calendar_id)[event.id] = event
      end
    end

    def delete_event(calendar_id, id)
      save do
        get_calendar_events(calendar_id).delete(id)
      end
    end

    def update_event(calendar_id, id, event)
      save do
        get_calendar_events(calendar_id)[id] = event
      end
    end

    def get_event(calendar_id, id)
      get_calendar_events(calendar_id)[id]
    end

    def insert_calendar(calendar)
      save do
        @store[calendar.id] ||= {}
        @store[calendar.id][:calendar] = calendar
        @store[calendar.id][:events] = {}
      end
    end

    def get_calendar(calendar_id)
      get_calendar_and_events(calendar_id)[:calendar]
    end

    private

    def get_calendar_and_events(calendar_id)
      return @store[calendar_id] if @store.has_key?(calendar_id)
      return @store.first[1] if @store.length > 0
      raise Google::Apis::ClientError.new("notFound")
    end

    def get_calendar_events(calendar_id)
      get_calendar_and_events(calendar_id)[:events]
    end

    def save
      obj = yield
      if (file)
        File.open(file, "w") { |f| f.write(@store.to_yaml) }
      end

      obj
    end
  end
end
