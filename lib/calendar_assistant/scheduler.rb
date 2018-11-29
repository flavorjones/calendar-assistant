class CalendarAssistant
  class Scheduler
    attr_reader :ca, :ers

    #
    #  class methods
    #
    def self.select_busy_events event_set
      dates_events = Hash.new
      event_set.events.each do |event|
        if event.private? || event.accepted? || event.self?
          date = event.start_date
          dates_events[date] ||= []
          dates_events[date] << event
        end
      end
      event_set.new dates_events
    end


    #
    #  instance methods
    #
    def initialize calendar_assistant, event_repositories
      @ca = calendar_assistant
      @ers = Array(event_repositories)
    end

    def available_blocks time_range
      avail = nil
      ers.each do |er|
        event_set = er.find time_range # array
        event_set = Scheduler.select_busy_events event_set # hash
        event_set.ensure_keys time_range.first.to_date .. time_range.last.to_date, only: true

        length = ChronicDuration.parse(ca.config.setting(Config::Keys::Settings::MEETING_LENGTH))
        ca.in_env do
          set_avail = event_set.available_blocks(length: length)
          avail = avail ? avail.intersection(set_avail, length: length) : set_avail
        end
      end
      avail
    end
  end
end
