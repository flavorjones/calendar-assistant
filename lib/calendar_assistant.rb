# coding: utf-8
require "google_calendar"
require "json"
require "yaml"
require "business_time"
require "google/apis/calendar_v3"
require "ice_cube"

class CalendarAssistant
  GCal = Google::Apis::CalendarV3

  EMOJI_WORLDMAP  = "🗺" # U+1F5FA WORLD MAP
  EMOJI_PLANE     = "🛪" # U+1F6EA NORTHEAST-POINTING AIRPLANE
  EMOJI_1_1       = "👫" # MAN AND WOMAN HOLDING HANDS

  CROSS_OUT_ON = "\e[9m"
  CROSS_OUT_OFF = "\e[29m"
  BOLD_ON = "\e[1m"
  BOLD_OFF = "\e[22m"
  ITALIC_ON = "\e[3m"
  ITALIC_OFF = "\e[23m"

  DEFAULT_CALENDAR_ID = "primary"

  attr_reader :service, :calendar

  def self.authorize profile_name
    Authorizer.authorize profile_name
  end

  def self.time_range_cast time_or_time_range
    if time_or_time_range.is_a?(Range)
      time_or_time_range.first.beginning_of_day..time_or_time_range.last.end_of_day
    else
      time_or_time_range.beginning_of_day..time_or_time_range.end_of_day
    end
  end

  def self.date_range_cast date_or_date_range
    if date_or_date_range.is_a?(Range)
      date_or_date_range.first.to_date..(date_or_date_range.last + 1.day).to_date
    else
      date_or_date_range.to_date..(date_or_date_range + 1.day).to_date
    end
  end

  def initialize profile_name
    @service = Authorizer.service profile_name
    @calendar = service.get_calendar DEFAULT_CALENDAR_ID
  end

  def find_events time_or_range
    range = CalendarAssistant.time_range_cast time_or_range
    events = service.list_events(DEFAULT_CALENDAR_ID,
                                 time_min: range.first.iso8601,
                                 time_max: range.last.iso8601,
                                 order_by: "startTime",
                                 single_events: true,
                                 max_results: 2000,
                                )
    events&.items || []
  end

  def find_location_events time_or_range
    find_events(time_or_range).select { |e| e.location_event? }
  end

  def create_location_event time_or_range, location
    # find pre-existing events that overlap
    existing_events = find_location_events time_or_range

    # augment event end date appropriately
    range = CalendarAssistant.date_range_cast time_or_range

    deleted_events = []
    modified_events = []

    event = GCal::Event.new start: GCal::EventDateTime.new(date: range.first.iso8601),
                            end: GCal::EventDateTime.new(date: range.last.iso8601),
                            summary: "#{EMOJI_WORLDMAP}  #{location}",
                            transparency: GCal::Event::TRANSPARENCY_NOT_BUSY

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
    attributes = event_attributes(event)
    declined = attributes.delete GCal::Event::RESPONSE_DECLINED
    attributes.delete GCal::Event::RESPONSE_ACCEPTED
    recurring = attributes.delete "recurring"

    s = sprintf "%-25.25s | #{BOLD_ON}%s#{BOLD_OFF}", event_date_description(event), event.summary
    s += sprintf(" #{ITALIC_ON}(%s)#{ITALIC_OFF}", attributes.join(", ")) unless attributes.empty?

    if options[:verbose]
      if recurring
        recurrence = IceCube::Schedule.from_ical(event.recurrence_rules(service))
        s += sprintf(" [%s]", recurrence) if recurring
      end
    end

    s = CROSS_OUT_ON + s + CROSS_OUT_OFF if declined
    s
  end

  def event_date_description event
    if event.all_day?
      start_date = event.start.date.is_a?(Date) ? event.start.date : Date.parse(event.start.date)
      end_date = event.end.date.is_a?(Date) ? event.end.date : Date.parse(event.end.date)
      if (end_date - start_date) <= 1
        event.start.to_s
      else
        sprintf("%s - %s", start_date, end_date - 1.day)
      end
    else
      if event.start.date_time.to_date == event.end.date_time.to_date
        sprintf("%s - %s", event.start.date_time.strftime("%Y-%m-%d  %H:%S"), event.end.date_time.strftime("%H:%S"))
      else
        sprintf("%s  -  %s", event.start.date_time.strftime("%Y-%m-%d %H:%S"), event.end.date_time.strftime("%Y-%m-%d %H:%S"))
      end
    end   
  end

  def event_attributes event
    [].tap do |attr|
      attr << "not-busy" if event.transparency
      if event.attendees.nil?
        attr << "self"
      else
        event.attendee(calendar.id).tap do |attendee|
          attr << attendee.response_status if attendee&.response_status
        end
      end
      attr << "recurring" if event.recurring_event_id
    end
  end
end

require "calendar_assistant/authorizer"
require "calendar_assistant/cli"
require "calendar_assistant/event_extensions"
