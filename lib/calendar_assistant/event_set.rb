class CalendarAssistant
  #
  #  note that `events` could be a few different data structures, depending.
  #
  #  - it could be an Array of Events
  #  - it could be a Hash, e.g. Date => Array of Events
  #  - it could be a bare Event
  #
  class EventSet
    def self.new event_repository, events=nil
      if events.is_a?(::Hash)
        return EventSet::Hash.new event_repository, events
      end
      if events.is_a?(::Array)
        return EventSet::Array.new event_repository, events
      end
      return EventSet::Bare.new event_repository, events
    end

    class Base
      attr_reader :event_repository, :events

      def initialize event_repository, events
        @event_repository = event_repository
        @events = events
      end

      def == rhs
        return false unless rhs.is_a?(self.class)
        self.event_repository == rhs.event_repository && self.events == rhs.events
      end

      def new new_events
        EventSet.new self.event_repository, new_events
      end

      def empty?
        return true if events.nil?
        return events.length == 0 if events.is_a?(Enumerable)
        false
      end
    end

    class Hash < EventSet::Base
      def ensure_keys keys
        keys.each do |key|
          events[key] = [] unless events.has_key?(key)
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

    class Array < EventSet::Base
    end

    class Bare < EventSet::Base
    end
  end
end
