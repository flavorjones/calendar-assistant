# coding: utf-8
require "google_calendar"
require "json"
require "yaml"
require "business_time"
require "google/apis/calendar_v3"
require "ice_cube"

class CalendarAssistant
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

  def self.range_cast time_or_time_range
    return time_or_time_range if time_or_time_range.is_a?(Range)
    time_or_time_range.beginning_of_day..time_or_time_range.end_of_day
  end

  def initialize profile_name
    @service = Authorizer.service profile_name
    @calendar = service.get_calendar DEFAULT_CALENDAR_ID
  end

  def find_events time_or_range
    range = CalendarAssistant.range_cast time_or_range
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

  def event_description event, options={}
    attributes = event_attributes(event)
    declined = attributes.delete Google::Apis::CalendarV3::Event::RESPONSE_DECLINED
    attributes.delete Google::Apis::CalendarV3::Event::RESPONSE_ACCEPTED
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
      if event.start.date == event.end.date
        event.start.to_s
      else
        sprintf("%s - %s", event.start, event.end)
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

class OldCalendarAssistant
  def create_location_event time_or_range, location_name
    start_time = time_or_range
    end_time = nil

    if time_or_range.is_a?(Range)
      start_time = time_or_range.first
      end_time = (time_or_range.last + 1.day).beginning_of_day
    end

    overlapping_events = if time_or_range.is_a?(Range)
                           find_location_events start_time..end_time
                         else
                           find_location_events start_time
                         end

    new_event = calendar.create_event do |event|
      event.title = "#{EMOJI_WORLDMAP}  #{location_name}"
      event.all_day = start_time
      event.end_time = end_time if end_time
    end

    deleted_events = []
    modified_events = []

    overlapping_events.each do |overlapping_event|
      oe_start = Time.parse overlapping_event.start_time
      oe_end = Time.parse overlapping_event.end_time
      ne_start = Time.parse new_event.start_time.to_s
      ne_end = Time.parse new_event.end_time.to_s

      if oe_start >= ne_start && oe_end <= ne_end
        calendar.delete_event overlapping_event
        deleted_events << overlapping_event
      else
        if oe_start >= ne_start && oe_end > ne_end
          overlapping_event.start_time = ne_end
          overlapping_event.end_time = oe_end
          calendar.save_event overlapping_event
        elsif oe_start < ne_start
          overlapping_event.end_time = ne_start
          calendar.save_event overlapping_event
        else
          raise "unknown date range overlap"
        end
        modified_events << overlapping_event
      end
    end

    retval = {created: [new_event]}
    retval[:deleted] = deleted_events if deleted_events.length > 0
    retval[:modified] = modified_events if modified_events.length > 0

    return retval
  end
end

require "calendar_assistant/authorizer"
require "calendar_assistant/cli"
require "calendar_assistant/event_extensions"
