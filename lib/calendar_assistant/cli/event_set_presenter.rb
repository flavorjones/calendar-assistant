class CalendarAssistant
  module CLI
    class EventSetPresenter < SimpleDelegator
      def initialize(obj, config:, event_presenter_class: CLI::EventPresenter)
        super(obj)
        @config = config
        @event_presenter_class = event_presenter_class
      end

      def to_s
        [
            title,
            description
        ].join("\n")
      end

      def title
        rainbow.wrap("#{event_repository.calendar.id} (all times in #{event_repository.calendar.time_zone})\n").italic
      end

      def description
        out = StringIO.new

        if __getobj__.is_a?(EventSet::Hash)
          events.each do |key, value|
            out.puts rainbow.wrap(key.to_s.capitalize + ":").bold.italic
            out.puts self.class.new(__getobj__.new(value), config: @config, event_presenter_class: @event_presenter_class).description
          end
          return out.string
        end

        _events = Array(events)

        return "No events in this time range.\n" if _events.empty?

        display_events = _events.select do |event|
          !@config.setting(CalendarAssistant::Config::Keys::Options::COMMITMENTS) || event.commitment?
        end

        printed_now = false

        display_events.each_with_object([]) do |event, out|
          printed_now = now! event, printed_now, out: out, presenter_class: @event_presenter_class
          out << @event_presenter_class.new(event).description
          pp event if @config.debug?
        end.join("\n")
      end

      def now!(event, printed_now, out:, presenter_class: CLI::EventPresenter)
        return true if printed_now
        return false if event.start_date != Date.today

        if event.start_time > Time.now
          out.puts presenter_class.new(CalendarAssistant::CLI::Helpers.now).description

          return true
        end

        false
      end

      private

      def rainbow
        @rainbow ||= Rainbow.global
      end
    end
  end
end