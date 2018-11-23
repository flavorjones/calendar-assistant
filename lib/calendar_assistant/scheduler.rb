class CalendarAssistant
  class Scheduler
    attr_reader :ca, :er

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
    def initialize calendar_assistant, event_repository
      @ca = calendar_assistant
      @er = event_repository
    end

    def available_blocks time_range
      event_set = er.find time_range # array
      event_set = Scheduler.select_busy_events event_set # hash
      event_set.ensure_keys time_range.first.to_date .. time_range.last.to_date

      length = ChronicDuration.parse(ca.config.setting(Config::Keys::Settings::MEETING_LENGTH))
      ca.in_env do
        event_set.available_blocks length: length
      end
    end
  end
end
