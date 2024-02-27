# coding: utf-8
class CalendarAssistant
  module CLI
    class Printer
      class LaunchUrlException < CalendarAssistant::BaseException; end

      attr_reader :io

      def initialize(io = STDOUT)
        @io = io
      end

      def launch(url)
        begin
          Launchy.open(url)
        rescue Exception => e
          raise LaunchUrlException.new(e)
        end
      end

      def puts(*args)
        io.puts(*args)
      end

      def prompt(query, default = nil)
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

      def print_events(ca, event_set, presenter_class: CLI::EventSetPresenter)
        puts presenter_class.new(event_set, config: ca.config).to_s
        puts
      end

      def print_available_blocks(ca, event_set, omit_title: false)
        ers = ca.config.calendar_ids.map { |calendar_id| ca.event_repository calendar_id }
        time_zones = ca.config.time_zones || ers.map { |er| er.calendar.time_zone }.uniq

        unless omit_title
          puts Rainbow(ers.map { |er| er.calendar.id }.join(", ")).italic
          puts Rainbow(sprintf("- looking for blocks at least %s long",
                               ChronicDuration.output(
                 ChronicDuration.parse(
                   ca.config.setting(Config::Keys::Settings::MEETING_LENGTH)
                 )
               ))).italic
          time_zones.each do |time_zone|
            puts Rainbow(sprintf("- between %s and %s in %s",
                                 ca.config.setting(Config::Keys::Settings::START_OF_DAY),
                                 ca.config.setting(Config::Keys::Settings::END_OF_DAY),
                                 time_zone)).italic
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
