require 'spec_helper'

RSpec.describe 'location', :type => :aruba do
  with_temp_calendar_assistant_home
  with_temp_file("fixtures.yml")
  let(:filename) { temp_file.path }

  before(:each) do
    event_list_factory(file: filename, calendar_id: CalendarAssistant::Config::DEFAULT_CALENDAR_ID, time_zone: "Pacific/Fiji") do
      [
          {start: "2018-01-01 9am", end: "2018-01-01 10am", summary: "accepted", options: :accepted},
      ]
    end

    event_list_factory(file: filename, load_events: true, calendar_id: "other_calendar@example.com", time_zone: "Pacific/Fiji") do
      [
          {start: "2018-02-01 9am", end: "2018-02-01 10am", summary: "accepted", options: :accepted},
      ]
    end
  end

  it "sets and prints location for the first of January, 2018" do
    run("./bin/calendar-assistant location 2018-01-01 --formatting=false --local-store=#{filename}")
    stop_all_commands
    expect(last_command_stopped).to be_successfully_executed
    expect(last_command_stopped.output).to eq (<<~OUT)
    primary (all times in Pacific/Fiji)

    No events in this time range.

    OUT

    run("./bin/calendar-assistant location-set Zanzibar 2018-01-01 --force --calendars=other_calendar@example.com --visibility=public --formatting=false --local-store=#{filename}")
    stop_all_commands

    expect(last_command_stopped).to be_successfully_executed
    expect(last_command_stopped.output).to eq (<<~OUT)
      primary (all times in Pacific/Fiji)
      
      Other_calendar@example.com:
      Created:
      2018-01-01                | 🌎 Zanzibar (not-busy, public, self)
      Primary:
      Created:
      2018-01-01                | 🌎 Zanzibar (not-busy, public, self)

    OUT
    run("./bin/calendar-assistant location 2018-01-01 --formatting=false --local-store=#{filename}")
    stop_all_commands

    expect(last_command_stopped).to be_successfully_executed
    expect(last_command_stopped.output).to eq (<<~OUT)
    primary (all times in Pacific/Fiji)

    2018-01-01                | 🌎 Zanzibar (not-busy, public, self)

    OUT
  end
end
