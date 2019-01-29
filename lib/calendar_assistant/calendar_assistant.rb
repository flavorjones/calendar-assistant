# coding: utf-8
class CalendarAssistant
  class BaseException < RuntimeError ; end

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
    @event_repositories = {} # type, calendar_id → event_repository
    @event_predicates = PredicateCollection.build(config.must_be, config.must_not_be)
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

  def lint_events time_range
    calendar_ids = config.calendar_ids
    if calendar_ids.length > 1
      raise BaseException, "CalendarAssistant#lint_events only supports one person (for now)"
    end
    event_repository(calendar_ids.first, type: :lint).find(time_range,  predicates: @event_predicates)
  end

  def find_events time_range
    calendar_ids = config.calendar_ids
    if calendar_ids.length > 1
      raise BaseException, "CalendarAssistant#find_events only supports one person (for now)"
    end
    event_repository(calendar_ids.first).find(time_range, predicates: @event_predicates)
  end

  def availability time_range
    calendar_ids = config.calendar_ids
    ers = calendar_ids.map do |calendar_id|
      event_repository calendar_id
    end
    Scheduler.new(self, ers).available_blocks(time_range, predicates: @event_predicates)
  end

  def find_location_events time_range
    event_repository(type: :location).find(time_range, predicates: @event_predicates)
  end

  def create_location_event time_range, location
    event_repository(type: :location).create(time_range, location, predicates: @event_predicates)
  end

  def event_repository calendar_id=Config::DEFAULT_CALENDAR_ID, type: :base
    @event_repositories[type] ||= {}
    @event_repositories[type][calendar_id] ||=
      @event_repository_factory.new_event_repository(@service, calendar_id, config: config, type: type)
  end
end
