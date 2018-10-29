# coding: utf-8
require "google/apis/calendar_v3"
require "json"
require "yaml"
require "business_time"
require "rainbow"
require "set"

require "calendar_assistant/version"

class CalendarAssistant
  GCal = Google::Apis::CalendarV3

  class BaseException < RuntimeError ; end

  EMOJI_WORLDMAP  = "🗺" # U+1F5FA WORLD MAP
  EMOJI_PLANE     = "🛪" # U+1F6EA NORTHEAST-POINTING AIRPLANE
  EMOJI_1_1       = "👫" # MAN AND WOMAN HOLDING HANDS

  DEFAULT_CALENDAR_ID = "primary"

  attr_reader :service, :calendar, :config

  def self.authorize profile_name
    config = CalendarAssistant::Config.new
    Authorizer.new(profile_name, config.token_store).authorize
  end

  def self.date_range_cast time_range
    time_range.first.to_date..(time_range.last + 1.day).to_date
  end

  def initialize config=CalendarAssistant::Config.new, event_repository: nil
    @config = config
    @service = Authorizer.new(config.profile_name, config.token_store).service
    @calendar = service.get_calendar DEFAULT_CALENDAR_ID
    @event_repository = event_repository || EventRepository.new(@service, DEFAULT_CALENDAR_ID)
  end

  def find_events time_range
    @event_repository.find(time_range)
  end

  def availability time_range
    length = ChronicDuration.parse(config.setting(Config::Keys::Settings::MEETING_LENGTH))

    start_of_day = Chronic.parse(config.setting(Config::Keys::Settings::START_OF_DAY))
    start_of_day = start_of_day - start_of_day.beginning_of_day

    end_of_day = Chronic.parse(config.setting(Config::Keys::Settings::END_OF_DAY))
    end_of_day = end_of_day - end_of_day.beginning_of_day

    events = find_events time_range
    date_range = time_range.first.to_date .. time_range.last.to_date

    # find relevant events and map them into dates
    dates_events = date_range.inject({}) { |de, date| de[date] = [] ; de }
    events.each do |event|
      if event.accepted?
        event_date = event.start.to_date!
        dates_events[event_date] ||= []
        dates_events[event_date] << event
      end
      dates_events
    end

    # iterate over the days finding free chunks of time
    avail_time = date_range.inject({}) do |avail_time, date|
      avail_time[date] ||= []
      date_events = dates_events[date]

      start_time = date.to_time + start_of_day
      end_time = date.to_time + end_of_day

      date_events.each do |e|
        if (e.start.date_time.to_time - start_time) >= length
          avail_time[date] << CalendarAssistant.available_block(start_time.to_datetime, e.start.date_time)
        end
        start_time = e.end.date_time.to_time
        break if start_time >= end_time
      end

      if end_time - start_time >= length
        avail_time[date] << CalendarAssistant.available_block(start_time.to_datetime, end_time.to_datetime)
      end

      avail_time
    end

    avail_time
  end

  def find_location_events time_range
    @event_repository.find(time_range).select { |e| e.location_event? }
  end

  def create_location_event time_range, location
    # find pre-existing events that overlap
    existing_events = find_location_events time_range

    # augment event end date appropriately
    range = CalendarAssistant.date_range_cast time_range

    deleted_events = []
    modified_events = []

    event = @event_repository.create(transparency: GCal::Event::Transparency::TRANSPARENT, start: range.first, end: range.last , summary: "#{EMOJI_WORLDMAP}  #{location}")

    existing_events.each do |existing_event|
      if existing_event.start.date >= event.start.date && existing_event.end.date <= event.end.date
        @event_repository.delete existing_event
        deleted_events << existing_event
      elsif existing_event.start.date <= event.end.date && existing_event.end.date > event.end.date
        @event_repository.update existing_event, start: range.last
        modified_events << existing_event
      elsif existing_event.start.date < event.start.date && existing_event.end.date >= event.start.date
        @event_repository.update existing_event, end: range.first
        modified_events << existing_event
      end
    end

    response = {created: [event]}
    response[:deleted] = deleted_events unless deleted_events.empty?
    response[:modified] = modified_events unless modified_events.empty?
    response
  end

  def event_description event
    s = sprintf("%-25.25s", event_date_description(event))

    date_ansi_codes = []
    date_ansi_codes << :bright if event.current?
    date_ansi_codes << :faint if event.past?
    s = date_ansi_codes.inject(Rainbow(s)) { |text, ansi| text.send ansi }

    s += Rainbow(sprintf(" | %s", event.view_summary)).bold

    attributes = []
    unless event.private?
      attributes << "recurring" if event.recurring_event_id
      attributes << "not-busy" unless event.busy?
      attributes << "self" if event.human_attendees.nil? && event.visibility != "private"
      attributes << "1:1" if event.one_on_one?
    end
    s += Rainbow(sprintf(" (%s)", attributes.to_a.sort.join(", "))).italic unless attributes.empty?

    s = Rainbow(Rainbow.uncolor(s)).faint.strike if event.declined?

    s
  end

  def event_date_description event
    if event.all_day?
      start_date = event.start.to_date
      end_date = event.end.to_date
      if (end_date - start_date) <= 1
        event.start.to_s
      else
        sprintf("%s - %s", start_date, end_date - 1.day)
      end
    else
      if event.start.date_time.to_date == event.end.date_time.to_date
        sprintf("%s - %s", event.start.date_time.strftime("%Y-%m-%d  %H:%M"), event.end.date_time.strftime("%H:%M"))
      else
        sprintf("%s  -  %s", event.start.date_time.strftime("%Y-%m-%d %H:%M"), event.end.date_time.strftime("%Y-%m-%d %H:%M"))
      end
    end
  end

  private

  def self.available_block start_time, end_time
    Google::Apis::CalendarV3::Event.new(
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: start_time),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: end_time),
      summary: "available"
    )
  end
end

require "calendar_assistant/config"
require "calendar_assistant/authorizer"
require "calendar_assistant/cli"
require "calendar_assistant/string_helpers"
require "calendar_assistant/extensions/event_date_time_extensions"
require "calendar_assistant/extensions/event_extensions"
require "calendar_assistant/event"
require "calendar_assistant/event_repository"
require "calendar_assistant/extensions/rainbow_extensions"