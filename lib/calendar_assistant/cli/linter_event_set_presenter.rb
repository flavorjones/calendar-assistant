class CalendarAssistant
  module CLI
    class LinterEventSetPresenter < EventSetPresenter
      def initialize(obj, config:, event_presenter_class: CLI::LinterEventPresenter)
        super(obj, config: config, event_presenter_class: event_presenter_class)
      end

      def title
        rainbow.wrap(<<~OUT)
        #{event_repository.calendar.id}
        - looking for events that need attention
        - all times in #{event_repository.calendar.time_zone}
        OUT
      end

      private

      def rainbow
        @rainbow ||= Rainbow.global
      end
    end
  end
end