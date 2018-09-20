class CalendarAssistant
  class CLIHelpers
    def self.time_or_time_range userspec
      if userspec =~ /\.\.\./
        start_userspec, end_userspec = userspec.split("...")
        start_time = Chronic.parse(start_userspec.strip) || raise("could not parse #{start_userspec.strip}")
        end_time   = Chronic.parse(end_userspec.strip) || raise("could not parse #{end_userspec.strip}")
        return start_time..end_time
      end
      Chronic.parse(userspec) || raise("could not parse #{userspec}")
    end

    def self.now
      GCal::Event.new start: GCal::EventDateTime.new(date_time: Time.now),
                      end: GCal::EventDateTime.new(date_time: Time.now),
                      summary: Rainbow("          now          ").inverse.faint
    end

    class Out
      attr_reader :io

      def initialize io=STDOUT
        @io = io
      end

      def print_now! event, ca, options, printed_now
        return true if printed_now
        return false if event.all_day?
        return false if event.start_date != Date.today

        if event.start.date_time > Time.now
          io.puts ca.event_description(CLIHelpers.now, options)
          return true
        end

        false
      end

      def print_events ca, events, options={}
        if events.nil? || events.empty?
          io.puts "No events in this time range."
          return
        end

        display_events = events.select do |event|
          ! options[:commitments] || ca.event_attributes(event).include?(GCal::Event::Attributes::COMMITMENT)
        end

        printed_now = false
        display_events.each do |event|
          printed_now = print_now! event, ca, options, printed_now
          io.puts ca.event_description(event, options)
          pp event if options[:debug]
        end
      end

      def launch url
        Launchy.open url
      end

      def puts *args
        io.puts(*args)
      end
    end
  end
end
