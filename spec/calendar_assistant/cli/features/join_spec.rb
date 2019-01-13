require 'spec_helper'

RSpec.describe 'join', :type => :aruba do
  freeze_time
  with_temp_calendar_assistant_home
  with_temp_file("fixtures.yml")
  let(:filename) { temp_file.path }

  before(:each) do
    event_list_factory(file: filename, time_zone: "Pacific/Fiji") do
      [
          {start: Time.now.to_s, summary: "accepted", options: [:accepted, :zoom]},
      ]
    end
  end

  before(:each) { run("./bin/calendar-assistant join --no-join --formatting=false --local-store=#{filename}") }
  before(:each) { stop_all_commands }

  subject { last_command_stopped }

  it { is_expected.to be_successfully_executed }

  it "joins the meeting for today's event" do
    expect(subject.output).to eq (<<~OUT)
      primary (all times in America/New_York)

      2019-01-13  00:00 - 23:59 | accepted

      http://company.zoom.us/1
    OUT
  end
end
