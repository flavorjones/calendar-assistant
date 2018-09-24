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
      GCal::Event.new start: GCal::EventDateTime.new(date_time: Time.now),
                      end: GCal::EventDateTime.new(date_time: Time.now),
                      summary: Rainbow("          now          ").inverse.faint
    end

    def self.find_av_uri ca, timespec
      time = Chronic.parse timespec
      range = time..(time+5.minutes)
      events = ca.find_events range

      [Google::Apis::CalendarV3::Event::RESPONSE_ACCEPTED,
       Google::Apis::CalendarV3::Event::RESPONSE_TENTATIVE,
       Google::Apis::CalendarV3::Event::RESPONSE_NEEDS_ACTION,
      ].each do |response|
        events.reverse.select do |event|
          event.response_status == response
        end.each do |event|
          return event.av_uri if event.av_uri
        end
      end

      nil
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
