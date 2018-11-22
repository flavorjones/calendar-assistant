class CalendarAssistant
  module DateHelpers
    def self.cast_dates attributes
      attributes.each_with_object({}) do |(key, value), object|
        if value.is_a?(Time) || value.is_a?(DateTime)
          object[key] = Google::Apis::CalendarV3::EventDateTime.new(date_time: value)
        elsif value.is_a?(Date)
          object[key] = Google::Apis::CalendarV3::EventDateTime.new(date: value.to_s)
        else
          object[key] = value
        end
      end
    end
  end
end

