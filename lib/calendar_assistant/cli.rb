require "thor"
require "chronic"
require "business_time"

module CalendarAssistant
  class CLI < Thor
    class_option :calendar, banner: "<google-calendar-id>", required: true, aliases: ["-c"]

    desc "where <datespec> <location>", "create an all-day event to declare your geographic location"
    def where chronic_date, location_name
      cal = CalendarAssistant.calendar_for options[:calendar]

      chronic_start_date = chronic_date
      chronic_end_date = nil
      if chronic_date =~ /\.\.\./
        chronic_start_date, chronic_end_date = chronic_date.split("...")
        chronic_start_date.strip!
        chronic_end_date.strip!
      end
      start_date = Chronic.parse chronic_start_date
      if chronic_end_date
        end_date = (Chronic.parse(chronic_end_date) + 1.day).beginning_of_day
      end

      e = cal.create_event do |event|
        event.title = "#{EMOJI_WORLDMAP} #{location_name}"
        event.all_day = start_date
        event.end_time = end_date if end_date
      end

      pp e.raw if e.respond_to?(:raw)
    end
  end
end
