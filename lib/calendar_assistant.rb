# coding: utf-8
require "google/apis/calendar_v3"
require "json"
require "yaml"
require "business_time"
require "rainbow"
require "set"

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

  def initialize profile_name
    @config = CalendarAssistant::Config.new
    @service = Authorizer.new(profile_name, config.token_store).service
    @calendar = service.get_calendar DEFAULT_CALENDAR_ID
  end

  def find_events time_range
    events = service.list_events(DEFAULT_CALENDAR_ID,
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

  def find_location_events time_range
    find_events(time_range).select { |e| e.location_event? }
  end

  def create_location_event time_range, location
    # find pre-existing events that overlap
    existing_events = find_location_events time_range

    # augment event end date appropriately
    range = CalendarAssistant.date_range_cast time_range

    deleted_events = []
    modified_events = []

    event = GCal::Event.new start: GCal::EventDateTime.new(date: range.first.iso8601),
                            end: GCal::EventDateTime.new(date: range.last.iso8601),
                            summary: "#{EMOJI_WORLDMAP}  #{location}",
                            transparency: GCal::Event::Transparency::TRANSPARENT

    event = service.insert_event DEFAULT_CALENDAR_ID, event

    existing_events.each do |existing_event|
      if existing_event.start.date >= event.start.date && existing_event.end.date <= event.end.date
        service.delete_event DEFAULT_CALENDAR_ID, existing_event.id
        deleted_events << existing_event
      elsif existing_event.start.date <= event.end.date && existing_event.end.date > event.end.date
        existing_event.update! start: GCal::EventDateTime.new(date: range.last)
        service.update_event DEFAULT_CALENDAR_ID, existing_event.id, existing_event
        modified_events << existing_event
      elsif existing_event.start.date < event.start.date && existing_event.end.date >= event.start.date
        existing_event.update! end: GCal::EventDateTime.new(date: range.first)
        service.update_event DEFAULT_CALENDAR_ID, existing_event.id, existing_event
        modified_events << existing_event
      end
    end

    response = {created: [event]}
    response[:deleted] = deleted_events unless deleted_events.empty?
    response[:modified] = modified_events unless modified_events.empty?
    response
  end

  def event_description event, options={}
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
end

require "calendar_assistant/config"
require "calendar_assistant/authorizer"
require "calendar_assistant/cli"
require "calendar_assistant/string_helpers"
require "calendar_assistant/event_extensions"
require "calendar_assistant/rainbow_extensions"
