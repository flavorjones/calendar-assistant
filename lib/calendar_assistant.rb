# coding: utf-8
require "google_calendar"
require "json"
require "yaml"
require "business_time"

class CalendarAssistant
  attr_reader :calendar

  CLIENT_ID_FILE = "client_id.json"
  CALENDAR_TOKENS_FILE = "calendar_tokens.yml"

  EMOJI_WORLDMAP  = "🗺" # U+1F5FA WORLD MAP
  EMOJI_PUSHPIN   = "📍" # U+1F4CD ROUND PUSHPIN
  EMOJI_FLAG      = "🚩" # U+1F6A9 TRIANGULAR FLAG ON POST
  EMOJI_PLANE     = "🛪" # U+1F6EA NORTHEAST-POINTING AIRPLANE
  EMOJI_1_1       = "👫" # MAN AND WOMAN HOLDING HANDS

  def self.token_for calendar_id
    calendar_tokens = File.exists?(CALENDAR_TOKENS_FILE) ?
                        YAML.load(File.read(CALENDAR_TOKENS_FILE)) :
                        Hash.new
    calendar_tokens[calendar_id]
  end

  def self.save_token_for calendar_id, refresh_token
    calendar_tokens = File.exists?(CALENDAR_TOKENS_FILE) ?
                        YAML.load(File.read(CALENDAR_TOKENS_FILE)) :
                        Hash.new
    calendar_tokens[calendar_id] = refresh_token
    File.open(CALENDAR_TOKENS_FILE, "w") { |f| f.write calendar_tokens.to_yaml }
  end

  def self.params_for calendar_id
    client_id = JSON.parse(File.read(CLIENT_ID_FILE))
    {
      :client_id     => client_id["installed"]["client_id"],
      :client_secret => client_id["installed"]["client_secret"],
      :calendar      => calendar_id,
      :redirect_url  => "urn:ietf:wg:oauth:2.0:oob",
      :refresh_token => CalendarAssistant.token_for(calendar_id),
    }
  end

  def self.calendar_for calendar_id
    Google::Calendar.new params_for(calendar_id)
  end

  def self.calendar_list_for calendar_id
    Google::CalendarList.new params_for(calendar_id)
  end

  def self.time_or_time_range userspec
    if userspec =~ /\.\.\./
      start_userspec, end_userspec = userspec.split("...")
      start_time = Chronic.parse start_userspec.strip
      end_time   = Chronic.parse end_userspec.strip
      return start_time..end_time
    end
    Chronic.parse userspec
  end

  def initialize calendar_id
    @calendar = CalendarAssistant.calendar_for calendar_id
  end

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

      if oe_end - oe_start <= 1.day
        calendar.delete_event overlapping_event
        deleted_events << overlapping_event
      else
        if oe_start >= ne_start && oe_end > ne_end
          overlapping_event.start_time = ne_end
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

  def find_location_events time_or_range
    find_events(time_or_range).find_all(&:assistant_location_event?)
  end

  def find_events time_or_range
    start_time, end_time = if time_or_range.is_a?(Range)
                             [time_or_range.first.beginning_of_day,
                              (time_or_range.last + 1.day).beginning_of_day]
                           else
                             [time_or_range.beginning_of_day,
                              (time_or_range + 1.day).beginning_of_day]
                           end

    calendar.find_events_in_range(start_time, end_time, max_results: 2000)
  end
end

require "calendar_assistant/cli"
require "calendar_assistant/event_extensions"
