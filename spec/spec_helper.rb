require_relative "../lib/calendar_assistant"
require_relative "./helpers/event_factory"

require "timecop"
require "securerandom"

ENV["THOR_DEBUG"] = "1" # UGH THOR

GCal = Google::Apis::CalendarV3

# set these to ridiculous values to make sure code is handling time environment properly
BusinessTime::Config.beginning_of_workday = "12pm"
BusinessTime::Config.end_of_workday = "12:30pm"
Time.zone = "Pacific/Fiji"
ENV['TZ'] = "Pacific/Fiji"

# make sure we don't do weird things with timecop
Timecop.safe_mode = true

module RspecDescribeHelpers
  def freeze_time
    around do |example|
      Timecop.freeze(Time.local(2018, 7, 13, 12, 1, 1)) do
        example.run
      end
    end
  end

  def set_date_to_a_weekday
    around do |example|
      Timecop.travel(Time.local(2018, 7, 11, 12, 1, 1)) do
        example.run
      end
    end
  end

  def with_temp_config_file &block
    with_temp_file("config_file", :temp_config_file, &block)
  end

  def with_temp_file(filename, identifier = :temp_file)
    contents = block_given? ? yield : ""

    let identifier do
      Tempfile.new filename
    end

    before do
      self.send(identifier).write contents
      self.send(identifier).close
    end

    after do
      self.send(identifier).close
      self.send(identifier).unlink
    end
  end
end

module RspecExampleHelpers
  def in_tz tz=time_zone, &block
    # this is totally not thread-safe
    orig_time_tz = Time.zone
    orig_env_tz = ENV['TZ']
    begin
      Time.zone = tz
      ENV['TZ'] = tz
      yield
    ensure
      Time.zone = orig_time_tz
      ENV['TZ'] = orig_env_tz
    end
  end

  def event_list_factory(date: Time.now, file: nil, calendar_id:, &block)
    service = CalendarAssistant::LocalService.new(file: file, load_events: false)
    service.insert_calendar(GCal::Calendar.new(id: calendar_id))
    EventFactory.new(service: service, calendar_id: calendar_id).for(date, &block)
  end

  def event_factory summary, time_range, stub={}
    if time_range.first.is_a?(Date)
      CalendarAssistant::Event.new(GCal::Event.new summary: summary,
                                                   start: GCal::EventDateTime.new(date: time_range.first),
                                                   end: GCal::EventDateTime.new(date: time_range.last))
    else
      CalendarAssistant::Event.new(GCal::Event.new summary: summary,
                                                   start: GCal::EventDateTime.new(date_time: time_range.first.to_datetime),
                                                   end: GCal::EventDateTime.new(date_time: time_range.last.to_datetime))
    end.tap do |event|
      stub.each do |attr, value|
        allow(event).to receive(attr).and_return(value)
      end
    end
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # This option will default to `:apply_to_host_groups` in RSpec 4 (and will
  # have no way to turn it off -- the option exists only for backwards
  # compatibility in RSpec 3). It causes shared context metadata to be
  # inherited by the metadata hash of host groups and examples, rather than
  # triggering implicit auto-inclusion in groups with matching metadata.
  config.shared_context_metadata_behavior = :apply_to_host_groups

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.order = :random
  Kernel.srand config.seed

  config.extend RspecDescribeHelpers
  config.include RspecExampleHelpers
end

RSpec::Matchers.define :event_date_time do |options|
  if options[:date]
    if options[:date].is_a?(String)
      match { |actual| actual.to_s == options[:date] }
    else
      match { |actual| actual.to_s == options[:date].iso8601 }
    end
  else
    raise "only supports dates right now"
  end
end
