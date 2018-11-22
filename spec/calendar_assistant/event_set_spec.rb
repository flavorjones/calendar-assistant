describe CalendarAssistant::EventSet do
  let(:event_repository) { instance_double "EventRepository" }
  let(:events) { [instance_double("Event1"), instance_double("Event2")] }

  describe "#initialize" do
    it "sets `event_repository` and `events` attributes" do
      event_set = described_class.new event_repository, events
      expect(event_set.event_repository).to eq(event_repository)
      expect(event_set.events).to eq(events)
    end

    it "default events to nil" do
      event_set = described_class.new event_repository
      expect(event_set.event_repository).to eq(event_repository)
      expect(event_set.events).to be_nil
    end
  end

  describe "#empty?" do
    let(:event_set) { described_class.new event_repository, events }

    context "`events` is an empty hash" do
      let(:events) { Hash.new }
      it { expect(event_set).to be_empty }
    end

    context "`events` is a non-empty hash" do
      let(:events) { { "2018-10-10" => [CalendarAssistant::Event.new(instance_double("GCal::Event"))] } }
      it { expect(event_set).to_not be_empty }
    end

    context "`events` is an empty array" do
      let(:events) { Array.new }
      it { expect(event_set).to be_empty }
    end

    context "`events` is a non-empty array" do
      let(:events) { [CalendarAssistant::Event.new(instance_double("GCal::Event"))] }
      it { expect(event_set).to_not be_empty }
    end

    context "`events` is an Event" do
      let(:events) { CalendarAssistant::Event.new instance_double("GCal::Event") }
      it { expect(event_set).to_not be_empty }
    end

    context "`events` is nil" do
      let(:events) { nil }
      it { expect(event_set).to be_empty }
    end
  end

  describe "#==" do
    context "event repositories are different objects" do
      let(:lhs) { described_class.new instance_double("EventRepository1"), [] }
      let(:rhs) { described_class.new instance_double("EventRepository2"), [] }
      it { expect(lhs == rhs).to be false }
    end

    context "events are different" do
      let(:event_repository) { instance_double("EventRepository") }
      let(:lhs) { described_class.new event_repository, [instance_double("Event1")] }
      let(:rhs) { described_class.new event_repository, [instance_double("Event2")] }
      it { expect(lhs == rhs).to be false }
    end

    context "event repositories are same and events are equal" do
      let(:event_repository) { instance_double("EventRepository") }
      let(:events) { [instance_double("Event")] }
      let(:lhs) { described_class.new event_repository, events }
      let(:rhs) { described_class.new event_repository, events }
      it { expect(lhs == rhs).to be true }
    end
  end

  describe "#new" do
    let(:other_events) { [instance_double("Event3"), instance_double("Event4")] }

    it "creates a new EventSet with the same EventRepository but different values" do
      original = described_class.new event_repository, events
      expected = described_class.new event_repository, other_events
      actual = original.new other_events
      expect(actual).to eq(expected)
    end
  end

  describe "#ensure_dates_as_keys" do
    it "needs a test for Array arg"
    it "needs a test for Range arg"
    it "needs a test for exception when called on an EventSet storing an Array"
  end

  describe "#available_blocks" do
    set_date_to_a_weekday # because otherwise if tests run on a weekend they'll fail

    let(:subject) { described_class.new event_repository, events }
    let(:event_repository) { CalendarAssistant::EventRepository.new service, calendar_id }
    let(:service) { instance_double("CalendarService") }
    let(:calendar_id) { "foo@example.com" }
    let(:calendar) { instance_double("Calendar") }
    let(:time_zone) { ENV['TZ'] }
    let(:config) { CalendarAssistant::Config.new options: config_options }
    let(:config_options) { Hash.new }

    before do
      allow(service).to receive(:get_calendar).and_return(calendar)
      allow(calendar).to receive(:time_zone).and_return(time_zone)
    end

    around do |example|
      config.in_env { example.run }
    end

    def expect_to_match_expected_avails found_avails
      expect(found_avails.keys).to eq(expected_avails.keys)
      found_avails.keys.each do |date|
        expect(found_avails[date].length).to eq(expected_avails[date].length)
        found_avails[date].each_with_index do |found_avail, j|
          expect(found_avail.start).to eq(expected_avails[date][j].start)
          expect(found_avail.end).to eq(expected_avails[date][j].end)
        end
      end
    end

    context "single date" do
      let(:time_range) { CalendarAssistant::CLIHelpers.parse_datespec "today" }
      let(:date) { time_range.first.to_date }

      context "with an event at the end of the day and other events later" do
        let(:events) do
          {
            date => [
              event_factory("zeroth", Chronic.parse("7:30am")..(Chronic.parse("8am"))),
              event_factory("first", Chronic.parse("8:30am")..(Chronic.parse("10am"))),
              event_factory("second", Chronic.parse("10:30am")..(Chronic.parse("12pm"))),
              event_factory("third", Chronic.parse("1:30pm")..(Chronic.parse("2:30pm"))),
              event_factory("fourth", Chronic.parse("3pm")..(Chronic.parse("5pm"))),
              event_factory("fifth", Chronic.parse("5:30pm")..(Chronic.parse("6pm"))),
              event_factory("sixth", Chronic.parse("6:30pm")..(Chronic.parse("7pm"))),
            ]
          }
        end

        let(:expected_avails) do
          {
            date => [
              event_factory("available", Chronic.parse("10am")..Chronic.parse("10:30am")),
              event_factory("available", Chronic.parse("12pm")..Chronic.parse("1:30pm")),
              event_factory("available", Chronic.parse("2:30pm")..Chronic.parse("3pm")),
              event_factory("available", Chronic.parse("5pm")..Chronic.parse("5:30pm")),
            ]
          }
        end

        it "returns an EventSet storing a hash of available blocks on each date" do
          expect_to_match_expected_avails subject.available_blocks.events
        end

        it "is in the calendar's time zone" do
          expect(subject.available_blocks.events[date].first.start_time.time_zone.name).to eq(time_zone)
        end
      end

      context "single date with no event at the end of the day" do
        let(:time_range) { CalendarAssistant::CLIHelpers.parse_datespec "today" }
        let(:date) { time_range.first.to_date }

        let(:events) do
          {
            date => [
              event_factory("first", Chronic.parse("8:30am")..(Chronic.parse("10am"))),
              event_factory("second", Chronic.parse("10:30am")..(Chronic.parse("12pm"))),
              event_factory("third", Chronic.parse("1:30pm")..(Chronic.parse("2:30pm"))),
              event_factory("fourth", Chronic.parse("3pm")..(Chronic.parse("5pm"))),
            ]
          }
        end

        let(:expected_avails) do
          {
            date => [
              event_factory("available", Chronic.parse("10am")..Chronic.parse("10:30am")),
              event_factory("available", Chronic.parse("12pm")..Chronic.parse("1:30pm")),
              event_factory("available", Chronic.parse("2:30pm")..Chronic.parse("3pm")),
              event_factory("available", Chronic.parse("5pm")..Chronic.parse("6pm")),
            ]
          }
        end

        it "finds chunks of free time at the end of the day" do
          expect_to_match_expected_avails subject.available_blocks.events
        end
      end

      context "completely free day with no events" do
        let(:time_range) { CalendarAssistant::CLIHelpers.parse_datespec "today" }
        let(:date) { time_range.first.to_date }

        let(:events) { { date => [] } }
        let(:expected_avails) do
          {
            date => [
              event_factory("available", Chronic.parse("9am")..Chronic.parse("6pm")),
            ]
          }
        end

        it "returns a big fat available block" do
          expect_to_match_expected_avails subject.available_blocks.events
        end
      end

      context "with end dates out of order" do
        # see https://github.com/flavorjones/calendar-assistant/issues/44 item 3
        let(:events) do
          {
            date => [
              event_factory("zeroth", Chronic.parse("11am")..(Chronic.parse("12pm"))),
              event_factory("first", Chronic.parse("11am")..(Chronic.parse("11:30am"))),
            ]
          }
        end

        let(:expected_avails) do
          {
            date => [
              event_factory("available", Chronic.parse("9am")..Chronic.parse("11am")),
              event_factory("available", Chronic.parse("12pm")..Chronic.parse("6pm")),
            ]
          }
        end

        it "returns correct available blocks" do
          expect_to_match_expected_avails subject.available_blocks.events
        end
      end

      context "with an event that crosses end-of-day" do
        # see https://github.com/flavorjones/calendar-assistant/issues/44 item 4
        let(:events) do
          {
            date => [
              event_factory("zeroth", Chronic.parse("11am")..(Chronic.parse("12pm"))),
              event_factory("first", Chronic.parse("5pm")..(Chronic.parse("7pm"))),
            ]
          }
        end

        let(:expected_avails) do
          {
            date => [
              event_factory("available", Chronic.parse("9am")..Chronic.parse("11am")),
              event_factory("available", Chronic.parse("12pm")..Chronic.parse("5pm")),
            ]
          }
        end

        it "returns correct available blocks" do
          expect_to_match_expected_avails subject.available_blocks.events
        end
      end
    end

    describe "multiple days" do
      let(:time_range) { CalendarAssistant::CLIHelpers.parse_datespec "2018-01-01..2018-01-03" }
      let(:events) do
        {
          Date.parse("2018-01-01") => [],
          Date.parse("2018-01-02") => [],
          Date.parse("2018-01-03") => [],
        }
      end
      let(:expected_avails) do
        {
          Date.parse("2018-01-01") => [event_factory("available", Chronic.parse("2018-01-01 9am")..Chronic.parse("2018-01-01 6pm"))],
          Date.parse("2018-01-02") => [event_factory("available", Chronic.parse("2018-01-02 9am")..Chronic.parse("2018-01-02 6pm"))],
          Date.parse("2018-01-03") => [event_factory("available", Chronic.parse("2018-01-03 9am")..Chronic.parse("2018-01-03 6pm"))],
        }
      end

      it "returns a hash of all dates" do
        expect_to_match_expected_avails subject.available_blocks.events
      end
    end

    describe "configurable parameters" do
      let(:time_range) { in_tz { CalendarAssistant::CLIHelpers.parse_datespec "today" } }
      let(:date) { in_tz { time_range.first.to_date } }

      let(:events) do
        in_tz do
          {
            date => [
              event_factory("first", Chronic.parse("8:30am")..(Chronic.parse("10am"))),
              event_factory("second", Chronic.parse("10:30am")..(Chronic.parse("12pm"))),
              event_factory("third", Chronic.parse("1:30pm")..(Chronic.parse("2:30pm"))),
              event_factory("fourth", Chronic.parse("3pm")..(Chronic.parse("5pm"))),
              event_factory("fifth", Chronic.parse("5:30pm")..(Chronic.parse("6pm"))),
              event_factory("fourth", Chronic.parse("6:30pm")..(Chronic.parse("7pm"))),
            ]
          }
        end
      end

      describe "start-of-day and end-of-day" do
        context "9-6" do
          let(:config_options) do
            {
              CalendarAssistant::Config::Keys::Settings::START_OF_DAY => "9am",
              CalendarAssistant::Config::Keys::Settings::END_OF_DAY => "6pm",
            }
          end

          let(:expected_avails) do
            {
              date => [
                event_factory("available", Chronic.parse("10am")..Chronic.parse("10:30am")),
                event_factory("available", Chronic.parse("12pm")..Chronic.parse("1:30pm")),
                event_factory("available", Chronic.parse("2:30pm")..Chronic.parse("3pm")),
                event_factory("available", Chronic.parse("5pm")..Chronic.parse("5:30pm")),
              ]
            }
          end

          it "finds blocks of time 30m or longer" do
            expect_to_match_expected_avails subject.available_blocks.events
          end
        end

        context "8-7" do
          let(:config_options) do
            {
              CalendarAssistant::Config::Keys::Settings::START_OF_DAY => "8am",
              CalendarAssistant::Config::Keys::Settings::END_OF_DAY => "7pm",
            }
          end

          let(:expected_avails) do
            {
              date => [
                event_factory("available", Chronic.parse("8am")..Chronic.parse("8:30am")),
                event_factory("available", Chronic.parse("10am")..Chronic.parse("10:30am")),
                event_factory("available", Chronic.parse("12pm")..Chronic.parse("1:30pm")),
                event_factory("available", Chronic.parse("2:30pm")..Chronic.parse("3pm")),
                event_factory("available", Chronic.parse("5pm")..Chronic.parse("5:30pm")),
                event_factory("available", Chronic.parse("6pm")..Chronic.parse("6:30pm")),
              ]
            }
          end

          it "finds blocks of time 30m or longer" do
            expect_to_match_expected_avails subject.available_blocks.events
          end
        end
      end

      context "EventRepository calendar is different from own time zone" do
        let(:time_zone) { "America/New_York" }
        let(:other_calendar) { instance_double("Calendar") }
        let(:other_time_zone) { "America/Los_Angeles" }

        before do
          allow(event_repository).to receive(:calendar).and_return(other_calendar)
          allow(other_calendar).to receive(:time_zone).and_return(other_time_zone)
        end

        let(:expected_avails) do
          in_tz do
            {
              date => [
                event_factory("available", Chronic.parse("12pm")..Chronic.parse("1:30pm")),
                event_factory("available", Chronic.parse("2:30pm")..Chronic.parse("3pm")),
                event_factory("available", Chronic.parse("5pm")..Chronic.parse("5:30pm")),
                event_factory("available", Chronic.parse("6pm")..Chronic.parse("6:30pm")),
                event_factory("available", Chronic.parse("7pm")..Chronic.parse("9pm")),
              ]
            }
          end
        end

        it "returns the free blocks in that time zone" do
          expect_to_match_expected_avails subject.available_blocks.events
        end

        it "is in the other calendar's time zone" do
          expect(subject.available_blocks.events[date].first.start_time.time_zone.name).to eq(other_time_zone)
        end
      end
    end
  end
end
