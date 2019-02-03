# coding: utf-8
class CalendarAssistant
  class LocationConfigValidator
    class LocationConfigValidationException < CalendarAssistant::BaseException;
    end

    def self.valid?(config)
      return if (config.calendar_ids - [ Config::DEFAULT_CALENDAR_ID ]).empty?
      return if !!config[CalendarAssistant::Config::Keys::Settings::NICKNAME]
      return if !!config[CalendarAssistant::Config::Keys::Options::FORCE]

      raise LocationConfigValidationException, "Managing location across multiple calendars when a nickname is not set is not recommended, use --force to override"
    end
  end
end