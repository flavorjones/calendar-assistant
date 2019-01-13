class CalendarAssistant
  class EventRepositoryFactory
    def self.new_event_repository service, calendar_id, config: CalendarAssistant::Config.new
      EventRepository.new service, calendar_id, config: config
    end
  end
end
