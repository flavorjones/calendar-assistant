class FakeService
  Result = Struct.new(:items)
  def initialize
    @calendars = {}
  end

  def list_events(calendar_id, options)
    time_min = Time.parse(options.fetch(:time_min))
    time_max = Time.parse(options.fetch(:time_max))
    search_range = time_min..time_max

    events = get_calendar(calendar_id).map do |id, event|
      event_range = (event.start.date_time || event.start.date)..(event.end.date_time || event.end.date)
      event if (event_range.first < search_range.last && event_range.last > search_range.first)
    end.compact
    Result.new(events)
  end

  def insert_event(calendar_id, event)
    get_calendar(calendar_id)[event.id] = event
  end

  def delete_event(calendar_id, id)
    get_calendar(calendar_id).delete(id)
  end

  def update_event(calendar_id, id, event)
    get_calendar(calendar_id)[id] = event
  end

  def get_event(calendar_id, id)
    get_calendar(calendar_id)[id]
  end

  private

  def get_calendar(calendar_id)
    @calendars[calendar_id] ||= {}
  end
end
