class CalendarAssistant
  class Scheduler
    attr_reader :config, :ca

    def initialize ca, config: Config.new
      @ca = ca
      @config = config
    end

    def available_blocks time_range
      length = ChronicDuration.parse(config.setting(Config::Keys::Settings::MEETING_LENGTH))

      start_of_day = Chronic.parse(config.setting(Config::Keys::Settings::START_OF_DAY))
      start_of_day = start_of_day - start_of_day.beginning_of_day

      end_of_day = Chronic.parse(config.setting(Config::Keys::Settings::END_OF_DAY))
      end_of_day = end_of_day - end_of_day.beginning_of_day

      events = ca.find_events time_range
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
      date_range.inject({}) do |avail_time, date|
        avail_time[date] ||= []
        date_events = dates_events[date]

        start_time = date.to_time + start_of_day
        end_time = date.to_time + end_of_day

        date_events.each do |e|
          if (e.start.date_time.to_time - start_time) >= length
            avail_time[date] << CalendarAssistant.available_block(start_time.to_datetime, e.start.date_time)
          end
          start_time = e.end.date_time.to_time
          break if start_time >= end_time
        end

        if end_time - start_time >= length
          avail_time[date] << CalendarAssistant.available_block(start_time.to_datetime, end_time.to_datetime)
        end

        avail_time
      end
    end
  end
end
