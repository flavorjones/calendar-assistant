class CalendarAssistant
  module HasDuration
    def self.duration_in_seconds(start_time, end_time)
      (end_time.to_datetime - start_time.to_datetime).days.to_i
    end

    def self.cast_datetime(datetime, time_zone = Time.zone.name)
      return datetime if datetime.is_a?(Google::Apis::CalendarV3::EventDateTime)
      Google::Apis::CalendarV3::EventDateTime.new(date_time: datetime.in_time_zone(time_zone).to_datetime)
    end

    def all_day?
      start.try(:date) || self.end.try(:date)
    end

    def past?
      if all_day?
        Date.today >= end_date
      else
        Time.now >= end_time
      end
    end

    def current?
      !(past? || future?)
    end

    def future?
      if all_day?
        start_date > Date.today
      else
        start_time > Time.now
      end
    end

    def cover?(event)
      event.start_date >= start_date && event.end_date <= end_date
    end

    def overlaps_start_of?(event)
      event.start_date <= end_date && event.end_date > end_date
    end

    def overlaps_end_of?(event)
      event.start_date < start_date && event.end_date >= start_date
    end

    def start_time
      if all_day?
        start_date.beginning_of_day
      else
        start.date_time
      end
    end

    def start_date
      if all_day?
        start.to_date
      else
        start_time.to_date
      end
    end

    def end_time
      if all_day?
        end_date.beginning_of_day
      else
        self.end.date_time
      end
    end

    def end_date
      if all_day?
        self.end.to_date
      else
        end_time.to_date
      end
    end

    def duration
      if all_day?
        days = (end_date - start_date).to_i
        return "#{days}d"
      end

      p = ActiveSupport::Duration.build(duration_in_seconds).parts
      s = []
      s << "#{p[:hours]}h" if p.has_key?(:hours)
      s << "#{p[:minutes]}m" if p.has_key?(:minutes)
      s.join(" ")
    end

    def duration_in_seconds
      HasDuration.duration_in_seconds start_time, end_time
    end

    def contains?(time)
      start_time <= time && time < end_time
    end
  end
end
