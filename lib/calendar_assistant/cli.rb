require "thor"
require "chronic"

module CalendarAssistant
  class CLI < Thor
    class_option :calendar, banner: "<google-calendar-id>", required: true, aliases: ["-c"]

    desc "where <datespec> <location>", "create an all-day event to declare your geographic location"
    def where chronic_date, location_name
      cal = CalendarAssistant.calendar_for options[:calendar]
      date = Chronic.parse chronic_date

      cal.create_event do |event|
        event.title = "#{EMOJI_WORLDMAP} #{location_name}"
        event.all_day = date
      end
    end
  end
end
