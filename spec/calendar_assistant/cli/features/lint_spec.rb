# coding: utf-8
require "spec_helper"

RSpec.describe "lint", :type => :aruba do
  with_temp_calendar_assistant_home
  with_temp_file("fixtures.yml")
  let(:filename) { temp_file.path }

  before(:each) do
    event_list_factory(file: filename, time_zone: "Pacific/Fiji") do
      [
        { start: "2018-01-01 9am", end: "2018-01-01 10am", summary: "accepted", options: :accepted },
        { start: "2018-01-01 9am", end: "2018-01-01 10am", summary: "self", options: :self },
        { start: "2018-01-01 10am", end: "2018-01-01 10:30am", summary: "meeting of the minds", options: :needs_action },
        { start: "2018-01-01 1pm", end: "2018-01-01 1:30pm", summary: "maybe", options: :tentative },
        { start: "2018-01-01 2pm", end: "2018-01-01 2:30pm", summary: "needs action", options: :needs_action },
        { start: "2018-01-01 4pm", end: "2018-01-01 4:30pm", summary: "check-in you never go to", options: :needs_action },
        { start: "2018-01-02 9am", end: "2018-01-02 10am", summary: "yeah", options: :self },
      ]
    end
  end

  before(:each) { run_command("calendar-assistant lint 2018-01-01 --formatting=false --local-store=#{filename}") }
  before(:each) { stop_all_commands }

  subject { last_command_stopped }

  it { is_expected.to be_successfully_executed }

  it "shows events that need action for the first of January, 2018" do
    expected = <<~OUT
      primary
      - looking for events that need attention
      - all times in Pacific/Fiji

      2018-01-01  10:00 - 10:30 | meeting of the minds (awaiting)
                                  attendees: 👍 three@example.com, 🤷 four@example.com
      2018-01-01  14:00 - 14:30 | needs action (awaiting)
                                  attendees: 👍 three@example.com, 🤷 four@example.com
      2018-01-01  16:00 - 16:30 | check-in you never go to (awaiting)
                                  attendees: 👍 three@example.com, 🤷 four@example.com

    OUT
    expect(subject.output).to eq(expected)
  end
end
