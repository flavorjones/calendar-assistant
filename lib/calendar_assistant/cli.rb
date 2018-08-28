require "thor"
require "chronic"

module CalendarAssistant
  class CLI < Thor
    option :id, required: true

    desc "where DATESPEC LOCATION", "create an all-day event to declare your geographic location"
    def where chronic_date, location_name
      cal = CalendarAssistant.calendar_for options[:id]
      date = Chronic.parse chronic_date

      cal.create_event do |event|
        event.title = "#{EMOJI_WORLDMAP} #{location_name}"
        event.all_day = date
      end
    end
  end
end
