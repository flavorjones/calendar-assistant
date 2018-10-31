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
      events = ca.find_events range

      [Google::Apis::CalendarV3::Event::Response::ACCEPTED,
       Google::Apis::CalendarV3::Event::Response::TENTATIVE,
       Google::Apis::CalendarV3::Event::Response::NEEDS_ACTION,
      ].each do |response|
        events.reverse.select do |event|
          event.response_status == response
        end.each do |event|
          return [event, event.av_uri] if event.av_uri
        end
      end

      nil
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
          puts ca.event_description(CLIHelpers.now)
          return true
        end

        false
      end

      def print_events ca, events, options={}
        unless options[:omit_title]
          puts Rainbow("#{ca.calendar.id} (all times in #{ca.calendar.time_zone})\n").italic
          options = options.merge(omit_title: true)
        end

        if events.is_a?(Hash)
          events.each do |key, value|
            puts Rainbow(key.to_s.capitalize + ":").bold.italic
            print_events ca, value, options
          end
          return
        end

        events = Array(events)
        if events.empty?
          puts "No events in this time range."
          return
        end

        display_events = events.select do |event|
          ! options[CalendarAssistant::Config::Keys::Options::COMMITMENTS] || event.commitment?
        end

        printed_now = false
        display_events.each do |event|
          printed_now = print_now! ca, event, printed_now
          puts ca.event_description(event)
          pp event if options[:debug]
        end

        puts
      end

      def print_available_blocks ca, events, options={}
        unless options[:omit_title]
          puts Rainbow(sprintf("%s\n- all times in %s\n- looking for blocks at least %s long\n",
                               ca.calendar.id,
                               ca.calendar.time_zone,
                               ChronicDuration.output(ChronicDuration.parse(ca.config.setting(Config::Keys::Settings::MEETING_LENGTH))))
                      ).italic
          options = options.merge(omit_title: true)
        end

        if events.is_a?(Hash)
          events.each do |key, value|
            puts(sprintf(Rainbow("Availability on %s:\n").bold,
                         key.strftime("%A, %B %-d")))
            print_available_blocks ca, value, options
            puts
          end
          return
        end

        events = Array(events)
        if events.empty?
          puts "  (No available blocks in this time range.)"
          return
        end

        events.each do |event|
          puts(sprintf(" • %s - %s",
                       event.start.date_time.strftime("%-l:%M%P"),
                       event.end.date_time.strftime("%-l:%M%P")))
          pp event if options[:debug]
        end
      end
    end
  end
end
