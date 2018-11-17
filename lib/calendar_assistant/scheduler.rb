class CalendarAssistant
  class Scheduler
    attr_reader :ca, :er

    def initialize ca, er
      @ca = ca
      @er = er
    end

    def available_blocks time_range
      ca.in_env do
        length = ChronicDuration.parse(ca.config.setting(Config::Keys::Settings::MEETING_LENGTH))

        events = er.find time_range
        date_range = time_range.first.to_date .. time_range.last.to_date

        # find relevant events and map them into dates
        dates_events = date_range.inject({}) { |de, date| de[date] = [] ; de }
        events.each do |event|
          if event.accepted?
            event_date = event.start.to_date!
            dates_events[event_date] ||= []
            dates_events[event_date] << event
          end
          dates_events
        end

        # iterate over the days finding free chunks of time
        er.in_tz do
          date_range.inject({}) do |avail_time, date|
            avail_time[date] ||= []
            date_events = dates_events[date]

            start_time = date.to_time +
                         BusinessTime::Config.beginning_of_workday.hour.hours +
                         BusinessTime::Config.beginning_of_workday.min.minutes

            end_time = date.to_time +
                       BusinessTime::Config.end_of_workday.hour.hours +
                       BusinessTime::Config.end_of_workday.min.minutes

            date_events.each do |e|
              next if ! e.end.date_time.to_time.during_business_hours?

              if (e.start.date_time.to_time - start_time) >= length
                avail_time[date] << available_block(start_time, e.start.date_time)
              end
              start_time = e.end.date_time.to_time
              break if ! start_time.during_business_hours?
            end

            if end_time - start_time >= length
              avail_time[date] << available_block(start_time, end_time)
            end

            avail_time
          end
        end
      end
    end

    private

    def available_block start_time, end_time
      Google::Apis::CalendarV3::Event.new(
        start: Google::Apis::CalendarV3::EventDateTime.new(date_time: start_time.in_time_zone(ca.calendar.time_zone)),
        end: Google::Apis::CalendarV3::EventDateTime.new(date_time: end_time.in_time_zone(ca.calendar.time_zone)),
        summary: "available"
      )
    end
  end
end
