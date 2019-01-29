class CalendarAssistant
  class EventRepositoryFactory
    def self.new_event_repository service, calendar_id, config: CalendarAssistant::Config.new, type: :base
      klass = case type
              when :location
                LocationEventRepository
              when :lint
                LintEventRepository
              else
                EventRepository
              end

      klass.new service, calendar_id, config: config
    end
  end
end
