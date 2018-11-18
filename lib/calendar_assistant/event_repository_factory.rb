class CalendarAssistant
  class EventRepositoryFactory
    def self.new_event_repository service, calendar_id
      EventRepository.new service, calendar_id
    end
  end
end
