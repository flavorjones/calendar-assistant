# coding: utf-8
class CalendarAssistant
  class BaseException < RuntimeError ; end

  EMOJI_WORLDMAP  = "🗺" # U+1F5FA WORLD MAP
  EMOJI_PLANE     = "🛪" # U+1F6EA NORTHEAST-POINTING AIRPLANE
  EMOJI_1_1       = "👫" # MAN AND WOMAN HOLDING HANDS

  attr_reader :service, :calendar, :config

  def self.date_range_cast time_range
    time_range.first.to_date..(time_range.last + 1.day).to_date
  end

  def self.in_tz time_zone, &block
    # this is totally not thread-safe
    orig_time_tz = Time.zone
    orig_env_tz = ENV['TZ']
    begin
      unless time_zone.nil?
        Time.zone = time_zone
        ENV['TZ'] = time_zone
      end
      yield
    ensure
      Time.zone = orig_time_tz
      ENV['TZ'] = orig_env_tz
    end
  end


  def initialize config=Config.new,
                 event_repository_factory: EventRepositoryFactory,
                 service:
    @config = config
    @service = service

    @calendar = service.get_calendar Config::DEFAULT_CALENDAR_ID
    @event_repository_factory = event_repository_factory
    @event_repositories = {} # calendar_id → event_repository
  end

  def in_env &block
    # this is totally not thread-safe
    config.in_env do
      in_tz do
        yield
      end
    end
  end

  def in_tz &block
    CalendarAssistant.in_tz calendar.time_zone do
      yield
    end
  end

  def find_events time_range
    calendar_ids = config.attendees
    if calendar_ids.length > 1
      raise BaseException, "CalendarAssistant#find_events only supports one person (for now)"
    end
    event_repository(calendar_ids.first).find(time_range)
  end

  def availability time_range
    calendar_ids = config.attendees
    ers = calendar_ids.map do |calendar_id|
      event_repository calendar_id
    end
    Scheduler.new(self, ers).available_blocks(time_range)
  end

  def find_location_events time_range
    event_set = event_repository.find(time_range)
    event_set.new event_set.events.select { |e| e.location_event? }
  end

  def create_location_event time_range, location
    # find pre-existing events that overlap
    existing_event_set = find_location_events time_range

    # augment event end date appropriately
    range = CalendarAssistant.date_range_cast time_range

    deleted_events = []
    modified_events = []

    event = event_repository.create(transparency: CalendarAssistant::Event::Transparency::TRANSPARENT, start: range.first, end: range.last , summary: "#{EMOJI_WORLDMAP}  #{location}")

    existing_event_set.events.each do |existing_event|
      if existing_event.start_date >= event.start_date && existing_event.end_date <= event.end_date
        event_repository.delete existing_event
        deleted_events << existing_event
      elsif existing_event.start_date <= event.end_date && existing_event.end_date > event.end_date
        event_repository.update existing_event, start: range.last
        modified_events << existing_event
      elsif existing_event.start_date < event.start_date && existing_event.end_date >= event.start_date
        event_repository.update existing_event, end: range.first
        modified_events << existing_event
      end
    end

    response = {created: [event]}
    response[:deleted] = deleted_events unless deleted_events.empty?
    response[:modified] = modified_events unless modified_events.empty?

    existing_event_set.new response
  end

  def event_repository calendar_id=Config::DEFAULT_CALENDAR_ID
    @event_repositories[calendar_id] ||= @event_repository_factory.new_event_repository(@service, calendar_id)
  end
end
