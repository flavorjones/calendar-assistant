class CalendarAssistant
  module CLI
    class Printer

      attr_reader :io

      def initialize io = STDOUT
        @io = io
      end

      def launch url
        Launchy.open url
      end

      def puts *args
        io.puts(*args)
      end

      def prompt query, default = nil
        loop do
          message = query
          message += " [#{default}]" if default
          message += ": "
          print Rainbow(message).bold
          answer = STDIN.gets.chomp.strip
          if answer.empty?
            return default if default
            puts Rainbow("Please provide an answer.").red
          else
            return answer
          end
        end
      end

      def print_now! event, printed_now, presenter_class: CLI::EventPresenter
        return true if printed_now
        return false if event.start_date != Date.today

        if event.start_time > Time.now
          puts presenter_class.new(CalendarAssistant::CLI::Helpers.now).description

          return true
        end

        false
      end

      def print_events ca, event_set, omit_title: false, presenter_class: CLI::EventPresenter
        unless omit_title
          er = event_set.event_repository
          puts Rainbow("#{er.calendar.id} (all times in #{er.calendar.time_zone})\n").italic
        end

        if event_set.is_a?(EventSet::Hash)
          event_set.events.each do |key, value|
            puts Rainbow(key.to_s.capitalize + ":").bold.italic
            print_events ca, event_set.new(value), omit_title: true, presenter_class: presenter_class
          end
          return
        end

        events = Array(event_set.events)
        if events.empty?
          puts "No events in this time range."
          return
        end

        display_events = events.select do |event|
          !ca.config.setting(CalendarAssistant::Config::Keys::Options::COMMITMENTS) || event.commitment?
        end

        printed_now = false
        display_events.each do |event|
          printed_now = print_now! event, printed_now, presenter_class: presenter_class
          puts presenter_class.new(event).description
          pp event if ca.config.debug?
        end

        puts
      end

      def print_available_blocks ca, event_set, omit_title: false
        ers = ca.config.attendees.map {|calendar_id| ca.event_repository calendar_id}
        time_zones = ers.map {|er| er.calendar.time_zone}.uniq

        unless omit_title
          puts Rainbow(ers.map {|er| er.calendar.id}.join(", ")).italic
          puts Rainbow(sprintf("- looking for blocks at least %s long",
                               ChronicDuration.output(
                                   ChronicDuration.parse(
                                       ca.config.setting(Config::Keys::Settings::MEETING_LENGTH))))).italic
          time_zones.each do |time_zone|
            puts Rainbow(sprintf("- between %s and %s in %s",
                                 ca.config.setting(Config::Keys::Settings::START_OF_DAY),
                                 ca.config.setting(Config::Keys::Settings::END_OF_DAY),
                                 time_zone,
                         )).italic
          end
          puts
        end

        if event_set.is_a?(EventSet::Hash)
          event_set.events.each do |key, value|
            puts(sprintf(Rainbow("Availability on %s:\n").bold,
                         key.strftime("%A, %B %-d")))
            print_available_blocks ca, event_set.new(value), omit_title: true
            puts
          end
          return
        end

        events = Array(event_set.events)
        if events.empty?
          puts "  (No available blocks in this time range.)"
          return
        end

        events.each do |event|
          line = []
          time_zones.each do |time_zone|
            line << sprintf("%s - %s",
                            event.start_time.in_time_zone(time_zone).strftime("%l:%M%P"),
                            event.end_time.in_time_zone(time_zone).strftime("%l:%M%P %Z"))
          end
          line.uniq!
          puts " • " + line.join(" / ") + Rainbow(" (" + event.duration + ")").italic
          pp event if ca.config.debug?
        end
      end
    end
  end
end
