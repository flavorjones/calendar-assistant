require 'securerandom'
class EventFactory
  def initialize service: CalendarAssistant::LocalService.new,
                 calendar_id: CalendarAssistant::Config::DEFAULT_CALENDAR_ID
    begin
      service.get_calendar(calendar_id)
    rescue
      service.insert_calendar(GCal::Calendar.new(id: calendar_id))

    end

    @event_repository = CalendarAssistant::EventRepository.new(service, calendar_id)
  end

  def for_in_hash(**default_attributes)
    yield.each_with_object({}) do |(key, values), hsh|
      hsh[key] = self.for(**default_attributes, &->() { values })
    end
  end

  def for(date: Time.now, **default_attributes)
    raise ArgumentError unless block_given?

    set_chronic_tz do
      now = date.is_a?(String) ? Chronic.parse(date) : date

      wrap(yield).map do |event_attributes|
        self_attendee = Google::Apis::CalendarV3::EventAttendee.new(id: 1, self: true)
        attrs = call_values(default_attributes).merge(event_attributes)
        options = wrap(attrs[:options])

        attrs[:attendees] = [self_attendee]

        attrs[:start], attrs[:end] = set_dates(attrs[:start], attrs[:end], now, options.delete(:all_day))


        (options).each do |option|
          set_option(attrs, self_attendee, option)
        end

        if (options & [:self, :one_on_one, :location_event]).empty?
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

  def set_option(attrs, self_attendee, option)
    case option
    when :recurring
      attrs[:recurring_event_id] = true
    when :self
      attrs[:attendees] = nil
    when :one_on_one
      attrs[:attendees].push Google::Apis::CalendarV3::EventAttendee.new(id: 2)
    when :declined
      self_attendee.response_status = CalendarAssistant::Event::Response::DECLINED
    when :accepted
      self_attendee.response_status = CalendarAssistant::Event::Response::ACCEPTED
    when :needs_action
      self_attendee.response_status = CalendarAssistant::Event::Response::NEEDS_ACTION
    when :tentative
      self_attendee.response_status = CalendarAssistant::Event::Response::TENTATIVE
    when :private
      attrs[:visibility] = CalendarAssistant::Event::Visibility::PRIVATE
    when :free
      attrs[:transparency] =  CalendarAssistant::Event::Transparency::TRANSPARENT
    when :busy
      attrs[:transparency] =  CalendarAssistant::Event::Transparency::OPAQUE
    when :location_event
      attrs[:summary] = "#{CalendarAssistant::EMOJI_WORLDMAP} #{ attrs[:summary] || "Zanzibar" }"
      new_dates = CalendarAssistant.date_range_cast(attrs[:start]..attrs[:end])
      set_option(attrs, self_attendee, :free)
      attrs[:start] = new_dates.first
      attrs[:end] = new_dates.last
    when :zoom
      attrs[:location] = "http://company.zoom.us/1"
    else
      raise "no factory option for: #{option}"
    end
  end

  def set_dates(start_time, end_time, now, all_day = false)
    # Jiggery pokery that copies CLI Helpers logic
    parsed_start = date_parse(start_time, now)

    if (end_time && start_time)
      dates = parsed_start, date_parse(end_time, now)
    elsif (parsed_start)
      dates = parsed_start.beginning_of_day, parsed_start.end_of_day
    end

    return dates.map(&:to_date) if all_day
    dates
  end

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
    parsed = Chronic.parse(attr, now: now)
    return nil if parsed.nil?
    parsed.to_datetime
  end

  def wrap(object)
    if object.nil?
      []
    elsif object.respond_to?(:to_ary)
      object.to_ary || [object]
    else
      [object]
    end
  end
end
