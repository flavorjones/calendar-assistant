#
#  this file extends the Google::EventDateTime class found in the "google_calendar" rubygem
#
autoload :Auth, "googleauth"
require "google/apis/calendar_v3"

class Google::Apis::CalendarV3::EventDateTime
  def to_date
    return nil if date.nil?
    return Date.parse(date) if date.is_a?(String)
    date
  end

  def to_date!
    return date_time.to_date if date.nil?
    to_date
  end

  def to_s
    return date.to_s if date
    date_time.strftime "%Y-%m-%d %H:%M"
  end

  def ==(rhs)
    if date
      return to_date == rhs.to_date
    end
    date_time == rhs.date_time
  end
end
