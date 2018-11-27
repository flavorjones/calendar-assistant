# coding: utf-8
class CalendarAssistant
  module CLIHelpers
    def self.parse_datespec userspec
      start_userspec, end_userspec = userspec.split(/ ?\.\.\.? ?/)

      if end_userspec.nil?
        time = Chronic.parse(userspec) || raise("could not parse #{userspec}")
        return time.beginning_of_day..time.end_of_day
      end

      start_time = Chronic.parse(start_userspec) || raise("could not parse #{start_userspec}")
      end_time = Chronic.parse(end_userspec) || raise("could not parse #{end_userspec}")

      if start_time.to_date == end_time.to_date
        start_time..end_time
      else
        start_time.beginning_of_day..end_time.end_of_day
      end
    end

    def self.now
      CalendarAssistant::Event.new(GCal::Event.new start: GCal::EventDateTime.new(date_time: Time.now),
                      end: GCal::EventDateTime.new(date_time: Time.now),
                      summary: Rainbow("          now          ").inverse.faint)
    end

    def self.find_av_uri ca, timespec
      time = Chronic.parse timespec
      range = time..(time+5.minutes)
      event_set = ca.find_events range

      [CalendarAssistant::Event::Response::ACCEPTED,
       CalendarAssistant::Event::Response::TENTATIVE,
       CalendarAssistant::Event::Response::NEEDS_ACTION,
      ].each do |response|
        event_set.events.reverse.select do |event|
          event.response_status == response
        end.each do |event|
          return [event_set.new(event), event.av_uri] if event.av_uri
        end
      end

      event_set.new(nil)
    end

    class Out
      attr_reader :io

      def initialize io=STDOUT
        @io = io
      end

      def launch url
        Launchy.open url
      end

      def puts *args
        io.puts(*args)
      end

      def prompt query, default=nil
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

      def print_now! ca, event, printed_now
        return true if printed_now
        return false if event.start_date != Date.today

        if event.start_time > Time.now
          puts event_description(CLIHelpers.now)
          return true
        end

        false
      end

      def print_events ca, event_set, omit_title: false
        unless omit_title
          er = event_set.event_repository
          puts Rainbow("#{er.calendar.id} (all times in #{er.calendar.time_zone})\n").italic
        end

        if event_set.events.is_a?(Hash)
          event_set.events.each do |key, value|
            puts Rainbow(key.to_s.capitalize + ":").bold.italic
            print_events ca, event_set.new(value), omit_title: true
          end
          return
        end

        events = Array(event_set.events)
        if events.empty?
          puts "No events in this time range."
          return
        end

        display_events = events.select do |event|
          ! ca.config.options[CalendarAssistant::Config::Keys::Options::COMMITMENTS] || event.commitment?
        end

        printed_now = false
        display_events.each do |event|
          printed_now = print_now! ca, event, printed_now
          puts event_description(event)
          pp event if ca.config.options[:debug]
        end

        puts
      end

      def print_available_blocks ca, event_set, omit_title: false
        unless omit_title
          er = event_set.event_repository
          puts Rainbow(sprintf("%s\n- looking for blocks at least %s long\n- between %s and %s in %s\n",
                               er.calendar.id,
                               ChronicDuration.output(ChronicDuration.parse(ca.config.setting(Config::Keys::Settings::MEETING_LENGTH))),
                               ca.config.setting(Config::Keys::Settings::START_OF_DAY),
                               ca.config.setting(Config::Keys::Settings::END_OF_DAY),
                               er.calendar.time_zone,
                              )).italic
        end

        if event_set.events.is_a?(Hash)
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
          puts(sprintf(" • %s - %s %s",
                       event.start.date_time.strftime("%l:%M%P"),
                       event.end.date_time.strftime("%l:%M%P %Z"),
                       Rainbow("(" + event.duration + ")").italic))
          pp event if ca.config.options[:debug]
        end
      end

      def event_description event
        s = sprintf("%-25.25s", event_date_description(event))

        date_ansi_codes = []
        date_ansi_codes << :bright if event.current?
        date_ansi_codes << :faint if event.past?
        s = date_ansi_codes.inject(Rainbow(s)) { |text, ansi| text.send ansi }

        s += Rainbow(sprintf(" | %s", event.view_summary)).bold

        attributes = []
        unless event.private?
          attributes << "recurring" if event.recurring?
          attributes << "not-busy" unless event.busy?
          attributes << "self" if event.human_attendees.nil? && event.visibility != "private"
          attributes << "1:1" if event.one_on_one?
          attributes << "awaiting" if event.awaiting?
        end

        attributes << event.visibility if event.explicit_visibility?

        s += Rainbow(sprintf(" (%s)", attributes.to_a.sort.join(", "))).italic unless attributes.empty?

        s = Rainbow(Rainbow.uncolor(s)).faint.strike if event.declined?

        s
      end

      def event_date_description event
        if event.all_day?
          start_date = event.start_date
          end_date = event.end_date
          if (end_date - start_date) <= 1
            event.start.to_s
          else
            sprintf("%s - %s", start_date, end_date - 1.day)
          end
        else
          if event.start_date == event.end_date
            sprintf("%s - %s", event.start.date_time.strftime("%Y-%m-%d  %H:%M"), event.end.date_time.strftime("%H:%M"))
          else
            sprintf("%s  -  %s", event.start.date_time.strftime("%Y-%m-%d %H:%M"), event.end.date_time.strftime("%Y-%m-%d %H:%M"))
          end
        end
      end
    end
  end
end
