require "spec_helper"

RSpec.describe "join", :type => :aruba do
  with_temp_calendar_assistant_home
  with_temp_file("fixtures.yml")
  let(:filename) { temp_file.path }

  before(:each) do
    event_list_factory(file: filename, time_zone: Time.zone.name) do
      [
        { start: "3 minutes ago", end: "3 minutes from now", summary: "accepted", options: [:accepted, :zoom] },
      ]
    end
  end

  before(:each) { run_command("calendar-assistant join --no-join --formatting=false --local-store=#{filename}") }
  before(:each) { stop_all_commands }

  subject { last_command_stopped }

  it { is_expected.to be_successfully_executed }

  it "joins the meeting for today's event" do
    expect(subject.output).to match(/http:\/\/company.zoom.us\/1$/)
  end
end
