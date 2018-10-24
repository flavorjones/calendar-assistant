class CalendarAssistant
  class Event < SimpleDelegator

    LOCATION_EVENT_REGEX = /^#{CalendarAssistant::EMOJI_WORLDMAP}/

    def location_event?
      !! (summary =~ LOCATION_EVENT_REGEX)
    end
  end
end