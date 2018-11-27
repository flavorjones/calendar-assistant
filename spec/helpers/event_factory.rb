require 'securerandom'
class EventFactory
  def initialize(service: CalendarAssistant::LocalService.new, calendar_id: "primary")
    begin
      service.get_calendar(calendar_id)
    rescue
      service.insert_calendar(GCal::Calendar.new(id: calendar_id))

    end

    @event_repository = CalendarAssistant::EventRepository.new(service, calendar_id)
  end

  def for(date: Time.now, **default_attributes)
    set_chronic_tz do
      now = date.is_a?(String) ? Chronic.parse(date) : date

      Array.wrap(yield).map do |event_attributes|
        self_attendee = Google::Apis::CalendarV3::EventAttendee.new(id: 1, self: true, response_status: CalendarAssistant::Event::Response::ACCEPTED)
        attrs = call_values(default_attributes).merge(event_attributes)

        attrs[:attendees] = [ self_attendee ]
        attrs[:start] = date_parse(attrs[:start], now)

        # Jiggery pokery that copies CLI Helpers logic

        if(attrs[:end])
          attrs[:end] = date_parse(attrs[:end], now)
        elsif(attrs[:start])
          attrs[:end] = attrs[:start].end_of_day
          attrs[:start] = attrs[:start].beginning_of_day
        end

        (attrs[:options] || []).each do |option|
          case option
          when :recurring
            attrs[:recurring_event_id] = true
          when :self
            attrs[:attendees] = nil
          when :one_on_one
            attrs[:attendees].push Google::Apis::CalendarV3::EventAttendee.new(id: 2)
          when :declined
            self_attendee.response_status = CalendarAssistant::Event::Response::DECLINED
          when :location_event
            attrs[:summary] = "#{CalendarAssistant::EMOJI_WORLDMAP} #{ attrs[:summary] || "Zanzibar" }"
            attrs[:transparency] = CalendarAssistant::Event::Transparency::TRANSPARENT
            new_dates = CalendarAssistant.date_range_cast(attrs[:start]..attrs[:end])
            attrs[:start] = new_dates.first
            attrs[:end] = new_dates.last
          else
            raise
          end
        end

        if ((attrs[:options] || []) & [:self, :one_on_one]).empty?
          attrs[:attendees] += [
            Google::Apis::CalendarV3::EventAttendee.new(id: 3),
            Google::Apis::CalendarV3::EventAttendee.new(id: 4)
          ]
        end

        attrs[:id] = SecureRandom.uuid unless attrs.has_key?(:id)

        @event_repository.create(attrs)
      end
    end
  end

  private

  def set_chronic_tz
    old_class = Chronic.time_class
    Chronic.time_class = Time.zone if Time.respond_to?(:zone) && Time.zone
    yield
  ensure
    Chronic.time_class = old_class
  end

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
