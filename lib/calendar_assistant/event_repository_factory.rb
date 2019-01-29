class CalendarAssistant
  class EventRepositoryFactory
    def self.new_event_repository service, calendar_id, config: CalendarAssistant::Config.new
      EventRepository.new service, calendar_id, config: config
    end

    def self.new_location_event_repository service, calendar_id, config: CalendarAssistant::Config.new
      LocationEventRepository.new service, calendar_id, config: config
    end

    def self.new_lint_event_repository service, calendar_id, config: CalendarAssistant::Config.new
      LintEventRepository.new service, calendar_id, config: config
    end
  end
end
