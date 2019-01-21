require 'spec_helper'

RSpec.describe 'show', :type => :aruba do
  with_temp_calendar_assistant_home
  with_temp_file("fixtures.yml")
  let(:filename) { temp_file.path }

  before(:each) do

    event_list_factory(file: filename, time_zone: "Pacific/Fiji") do
      [
          {start: "2018-01-01 9am", end: "2018-01-01 10am", summary: "accepted", options: :accepted},
          {start: "2018-01-01 9am", end: "2018-01-01 10am", summary: "self", options: :self},
          {start: "2018-01-01 9am", end: "2018-01-01 10am", summary: "declined", options: :declined},
          {start: "2018-01-01 9am", end: "2018-01-01 10am", summary: "maybe", options: :tentative},
          {start: "2018-01-01 9am", end: "2018-01-01 10am", summary: "needs action", options: :needs_action},
          {start: "2018-01-01 9am", end: "2018-01-01 10am", summary: "private", options: :private},
          {start: "2018-01-02 9am", end: "2018-01-02 10am", summary: "yeah", options: :self},
          {start: "2018-01-03 9am", end: "2018-01-03 10am", summary: "sure", options: :self},
          {start: "2018-01-04 9am", end: "2018-01-04 10am", summary: "ignore this date", options: :declined},
          {start: "2018-01-07", end: "2018-01-09", summary: "this is an all day busy event", options: [:all_day, :busy]}
      ]
    end
  end

  before(:each) { stop_all_commands }

  subject { last_command_stopped }

  context "when there are no predicates" do
    before(:each) { run("./bin/calendar-assistant show 2018-01-01 --formatting=false --local-store=#{filename}") }

    it { is_expected.to be_successfully_executed }

    it "prints events for the first of January, 2018" do
      expect(subject.output).to eq (<<~OUT)
        primary (all times in Pacific/Fiji)

        2018-01-01  09:00 - 10:00 | accepted
        2018-01-01  09:00 - 10:00 | self (self)
        2018-01-01  09:00 - 10:00 | declined
        2018-01-01  09:00 - 10:00 | maybe (tentative)
        2018-01-01  09:00 - 10:00 | needs action (awaiting)
        2018-01-01  09:00 - 10:00 | private

      OUT
    end
  end

  context "when passed a predicate" do
    before(:each) { run("./bin/calendar-assistant show 2018-01-01 --must-not-be=self tentative --formatting=false --local-store=#{filename}") }

    it { is_expected.to be_successfully_executed }

    it "prints events filtered by those predicate" do
      expect(subject.output).to eq (<<~OUT)
        primary (all times in Pacific/Fiji)

        2018-01-01  09:00 - 10:00 | accepted
        2018-01-01  09:00 - 10:00 | declined
        2018-01-01  09:00 - 10:00 | needs action (awaiting)
        2018-01-01  09:00 - 10:00 | private

      OUT
    end
  end
end
