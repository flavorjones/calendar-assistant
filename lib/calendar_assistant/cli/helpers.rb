# coding: utf-8
class CalendarAssistant
  module CLI
    module Helpers
      class ChronicParseException < CalendarAssistant::BaseException
      end

      def self.parse_datespec(userspec)
        start_userspec, end_userspec = userspec.split(/ ?\.\.\.? ?/)

        if end_userspec.nil?
          time = Chronic.parse(userspec) || raise(ChronicParseException, "could not parse '#{userspec}'")
          return time.beginning_of_day..time.end_of_day
        end

        start_time = Chronic.parse(start_userspec) || raise(ChronicParseException, "could not parse '#{start_userspec}'")
        end_time = Chronic.parse(end_userspec) || raise(ChronicParseException, "could not parse '#{end_userspec}'")

        if start_time.to_date == end_time.to_date
          start_time..end_time
        else
          start_time.beginning_of_day..end_time.end_of_day
        end
      end

      def self.now
        CalendarAssistant::Event.new(
          Google::Apis::CalendarV3::Event.new(start: Google::Apis::CalendarV3::EventDateTime.new(date_time: Time.now),
                                              end: Google::Apis::CalendarV3::EventDateTime.new(date_time: Time.now),
                                              summary: Rainbow("          now          ").inverse.faint)
        )
      end

      def self.find_av_uri(ca, timespec)
        time = Chronic.parse timespec
        range = time..(time + 5.minutes)
        event_set = ca.find_events range

        [CalendarAssistant::Event::Response::ACCEPTED,
         CalendarAssistant::Event::Response::TENTATIVE,
         CalendarAssistant::Event::Response::NEEDS_ACTION].each do |response|
          event_set.events.reverse.select do |event|
            event.response_status == response
          end.each do |event|
            return [event_set.new(event), event.av_uri] if event.av_uri
          end
        end

        event_set.new(nil)
      end
    end
  end
end
