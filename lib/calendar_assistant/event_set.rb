class CalendarAssistant
  class EventSet
    #
    #  note that `events` could be a few different data structures, depending.
    #
    #  - it could be an Array of Events
    #  - it could be a hash, e.g. Date => Array of Events
    #  - it could be a bare Event
    #
    #  you can argue the wisdom of allowing these different
    #  structures, sure. yeah.
    #
    #  TODO: break it into different subclasses.
    #
    attr_reader :event_repository, :events

    def initialize event_repository, events=nil
      @event_repository = event_repository
      @events = events
    end

    def empty?
      return true if events.nil?
      if events.is_a?(Enumerable)
        return events.length == 0
      end
      false
    end

    def == rhs
      return false unless rhs.is_a?(EventSet)
      self.event_repository == rhs.event_repository && self.events == rhs.events
    end

    def new new_events
      self.class.new self.event_repository, new_events
    end

    def ensure_dates_as_keys dates
      dates.each do |date|
        events[date] = [] unless events.has_key?(date)
      end
    end

    def available_blocks length: 1
      event_repository.in_tz do
        dates = events.keys.sort

        # iterate over the days finding free chunks of time
        _avail_time = dates.inject({}) do |avail_time, date|
          avail_time[date] ||= []
          date_events = events[date]

          start_time = date.to_time.to_datetime +
                       BusinessTime::Config.beginning_of_workday.hour.hours +
                       BusinessTime::Config.beginning_of_workday.min.minutes
          end_time = date.to_time.to_datetime +
                     BusinessTime::Config.end_of_workday.hour.hours +
                     BusinessTime::Config.end_of_workday.min.minutes

          date_events.each do |e|
            # ignore events that are outside my business day
            next if Time.before_business_hours?(e.end_time.to_time)
            next if Time.after_business_hours?(e.start_time.to_time)

            if (e.start_time - start_time).days.to_i >= length
              avail_time[date] << event_repository.available_block(start_time, e.start_time)
            end
            start_time = [e.end_time, start_time].max
            break if ! start_time.during_business_hours?
          end

          if (end_time - start_time).days.to_i >= length
            avail_time[date] << event_repository.available_block(start_time, end_time)
          end

          avail_time
        end

        new _avail_time
      end
    end
  end
end
