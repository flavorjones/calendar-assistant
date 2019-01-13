class CalendarAssistant
  class EventRepositoryFactory
    def self.new_event_repository service, calendar_id, location_icons = CalendarAssistant::Config::DEFAULT_SETTINGS[CalendarAssistant::Config::Keys::Settings::LOCATION_ICONS]
      EventRepository.new service, calendar_id, location_icons
    end
  end
end
