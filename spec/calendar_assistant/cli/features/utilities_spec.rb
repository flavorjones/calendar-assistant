# coding: utf-8
require 'spec_helper'

RSpec.describe 'utility features', :type => :aruba do
  with_temp_calendar_assistant_home
  with_temp_file("fixtures.yml")
  let(:filename) { temp_file.path }

  before(:each) do
    event_list_factory(file: filename, time_zone: "Pacific/Fiji") do
      [
        {start: "2018-01-01 9am", end: "2018-01-01 10am", summary: "accepted", options: :accepted},
      ]
    end
  end

  subject { last_command_stopped }

  describe "config" do
    before(:each) { run_command("./bin/calendar-assistant config --formatting=false") }
    before(:each) { stop_all_commands }

    it { is_expected.to be_successfully_executed }

    it "prints config" do
      expect(subject.output).to match(/^\[settings\].*/)
    end
  end

  describe "version" do
    before(:each) { run_command("./bin/calendar-assistant version --formatting=false") }
    before(:each) { stop_all_commands }

    it { is_expected.to be_successfully_executed }

    it "prints version" do
      expect(subject.output.chomp).to eq CalendarAssistant::VERSION
    end
  end

  describe "authorize" do
    before(:each) { run_command("./bin/calendar-assistant authorize --formatting=false") }
    before(:each) { stop_all_commands }

    it { is_expected.to be_successfully_executed }

    it "prints authorize help" do
      expect(subject.output).to match(/^Usage:\n  calendar-assistant authorize PROFILE_NAME/)
    end
  end

  describe "help" do
    before(:each) { run_command("./bin/calendar-assistant help --formatting=false") }
    before(:each) { stop_all_commands }

    it { is_expected.to be_successfully_executed }

    it "prints help" do
      expect(subject.output).to match(/^Commands:\n  calendar-assistant authorize/)
    end
  end


  describe "setup" do
    it "has interactive steps and seems too hard to test"
  end
end
