require 'securerandom'
class EventFactory
  def initialize(service: CalendarAssistant::LocalService.new, calendar_id: "primary")
    @event_repository = CalendarAssistant::EventRepository.new(service, calendar_id)
  end

  def for(date: Time.now, **default_attributes)
    now = date.is_a?(String) ? Chronic.parse(date) : date
    Array.wrap(yield).map do |event_attributes|
      attrs = call_values(default_attributes).merge(event_attributes)

      attrs[:start] = date_parse(attrs[:start], now)
      attrs[:end] = date_parse(attrs[:end], now)
      attrs[:id] = SecureRandom.uuid unless attrs.has_key?(:id)

      (event_attributes[:options] || []).each do |option|
        case option
        when :recurring
          attrs[:recurring_event_id] = true

        when :self
          attrs[:attendees] = [Google::Apis::CalendarV3::EventAttendee.new(id: 1)]
        when :one_on_one
          attrs[:attendees] = [Google::Apis::CalendarV3::EventAttendee.new(id: 1), Google::Apis::CalendarV3::EventAttendee.new(id: 2)]
        else
          raise
        end
      end

      @event_repository.create(attrs)
    end
  end

  private

  def call_values(attributes)
    attributes
      .each_with_object({}) do |(key, value), hsh|
      hsh[key] = value.respond_to?(:call) ? value.call : value
    end
  end

  def date_parse(attr, now)
    Chronic.parse(attr, now: now)
  end
end