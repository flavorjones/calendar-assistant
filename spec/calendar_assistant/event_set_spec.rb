describe CalendarAssistant::EventSet do
  let(:event_repository) { instance_double "EventRepository" }
  let(:events) { [instance_double("Event1"), instance_double("Event2")] }

  def expect_to_match_expected_events found_avails
    expect(found_avails.keys).to eq(expected_events.keys)
    found_avails.keys.each do |date|
      expect(found_avails[date].length).to(
        eq(expected_events[date].length),
        sprintf("for date %s: expected %d got %d", date, expected_events[date].length, found_avails[date].length)
      )
      found_avails[date].each_with_index do |found_avail, j|
        expect(found_avail.start).to eq(expected_events[date][j].start)
        expect(found_avail.end).to eq(expected_events[date][j].end)
      end
    end
  end

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

  describe "#ensure_keys" do
    subject { described_class.new event_repository, {"z" => 1} }

    context "Array arg" do
      context "with only: true" do
        it "creates a key for each Array value and removes non-matching keys" do
          subject.ensure_keys ["a", "b", "c"], only: true
          expect(subject.events.keys).to eq(["a", "b", "c"])
          expect(subject.events["a"]).to eq([])
        end
      end

      context "with only: false" do
        it "creates a key for each Array value" do
          subject.ensure_keys ["a", "b", "c"], only: false
          expect(subject.events.keys).to eq(["z", "a", "b", "c"])
          expect(subject.events["a"]).to eq([])
        end
      end

      context "default only value" do
        it "creates a key for each Array value" do
          subject.ensure_keys ["a", "b", "c"]
          expect(subject.events.keys).to eq(["z", "a", "b", "c"])
          expect(subject.events["a"]).to eq([])
        end
      end
    end

    context "Range arg" do
      context "with only: true" do
        it "creates a key for each Range value and removes non-matching keys" do
          subject.ensure_keys "a" .. "c", only: true
          expect(subject.events.keys).to eq(["a", "b", "c"])
          expect(subject.events["a"]).to eq([])
        end
      end

      context "with only: false" do
        it "creates a key for each Range value" do
          subject.ensure_keys "a" .. "c", only: false
          expect(subject.events.keys).to eq(["z", "a", "b", "c"])
          expect(subject.events["a"]).to eq([])
        end
      end

      context "default only value" do
        it "creates a key for each Range value" do
          subject.ensure_keys "a" .. "c"
          expect(subject.events.keys).to eq(["z", "a", "b", "c"])
          expect(subject.events["a"]).to eq([])
        end
      end
    end
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

        let(:expected_events) do
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
          expect_to_match_expected_events subject.available_blocks.events
        end

        it "is in the calendar's time zone" do
          expect(subject.available_blocks.events[date].first.start_time.time_zone.name).to eq(time_zone)
        end

        context "a meeting length is passed" do
          let(:expected_events) do
            {
              date => [
                event_factory("available", Chronic.parse("12pm")..Chronic.parse("1:30pm")),
              ]
            }
          end

          it "ignores available blocks shorter than that length" do
            expect_to_match_expected_events subject.available_blocks(length: 31.minutes).events
          end
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

        let(:expected_events) do
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
          expect_to_match_expected_events subject.available_blocks.events
        end
      end

      context "completely free day with no events" do
        let(:time_range) { CalendarAssistant::CLIHelpers.parse_datespec "today" }
        let(:date) { time_range.first.to_date }

        let(:events) { { date => [] } }
        let(:expected_events) do
          {
            date => [
              event_factory("available", Chronic.parse("9am")..Chronic.parse("6pm")),
            ]
          }
        end

        it "returns a big fat available block" do
          expect_to_match_expected_events subject.available_blocks.events
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

        let(:expected_events) do
          {
            date => [
              event_factory("available", Chronic.parse("9am")..Chronic.parse("11am")),
              event_factory("available", Chronic.parse("12pm")..Chronic.parse("6pm")),
            ]
          }
        end

        it "returns correct available blocks" do
          expect_to_match_expected_events subject.available_blocks.events
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

        let(:expected_events) do
          {
            date => [
              event_factory("available", Chronic.parse("9am")..Chronic.parse("11am")),
              event_factory("available", Chronic.parse("12pm")..Chronic.parse("5pm")),
            ]
          }
        end

        it "returns correct available blocks" do
          expect_to_match_expected_events subject.available_blocks.events
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
      let(:expected_events) do
        {
          Date.parse("2018-01-01") => [event_factory("available", Chronic.parse("2018-01-01 9am")..Chronic.parse("2018-01-01 6pm"))],
          Date.parse("2018-01-02") => [event_factory("available", Chronic.parse("2018-01-02 9am")..Chronic.parse("2018-01-02 6pm"))],
          Date.parse("2018-01-03") => [event_factory("available", Chronic.parse("2018-01-03 9am")..Chronic.parse("2018-01-03 6pm"))],
        }
      end

      it "returns a hash of all dates" do
        expect_to_match_expected_events subject.available_blocks.events
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

          let(:expected_events) do
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
            expect_to_match_expected_events subject.available_blocks.events
          end
        end

        context "8-7" do
          let(:config_options) do
            {
              CalendarAssistant::Config::Keys::Settings::START_OF_DAY => "8am",
              CalendarAssistant::Config::Keys::Settings::END_OF_DAY => "7pm",
            }
          end

          let(:expected_events) do
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
            expect_to_match_expected_events subject.available_blocks.events
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

        let(:expected_events) do
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
          expect_to_match_expected_events subject.available_blocks.events
        end

        it "is in the other calendar's time zone" do
          expect(subject.available_blocks.events[date].first.start_time.time_zone.name).to eq(other_time_zone)
        end
      end
    end
  end

  describe "#intersection" do
    let(:service) { instance_double("CalendarService") }
    let(:calendar_id1) { "foo@example.com" }
    let(:calendar_id2) { "bar@example.com" }
    let(:calendar1) { instance_double("Calendar") }
    let(:calendar2) { instance_double("Calendar") }
    let(:time_zone1) { ENV['TZ'] }
    let(:time_zone2) { time_zone1 }

    let(:er1) { CalendarAssistant::EventRepository.new service, calendar_id1 }
    let(:set1) { CalendarAssistant::EventSet.new er1, events1 }
    let(:er2) { CalendarAssistant::EventRepository.new service, calendar_id2 }
    let(:set2) { CalendarAssistant::EventSet.new er2, events2 }

    before do
      allow(service).to receive(:get_calendar).with(calendar_id1).and_return(calendar1)
      allow(service).to receive(:get_calendar).with(calendar_id2).and_return(calendar2)
      allow(calendar1).to receive(:time_zone).and_return(time_zone1)
      allow(calendar2).to receive(:time_zone).and_return(time_zone2)
    end

    context "non-intersecting sets" do
      let(:events1)  do
        {
          Date.parse("2018-01-01") => [
            event_factory("1:0", Chronic.parse("2018-01-01 9am")..Chronic.parse("2018-01-01 11am")),
          ]
        }
      end

      let(:events2)  do
        {
          Date.parse("2018-01-01") => [
            event_factory("1:0", Chronic.parse("2018-01-01 11am")..Chronic.parse("2018-01-01 2pm")),
          ]
        }
      end

      let(:expected_events)  do
        {
          Date.parse("2018-01-01") => []
        }
      end

      it { expect_to_match_expected_events set1.intersection(set2).events }
      it { expect_to_match_expected_events set2.intersection(set1).events }
    end

    context "overlapping events" do
      let(:events1)  do
        {
          Date.parse("2018-01-01") => [
            event_factory("1:0", Chronic.parse("2018-01-01 9am")..Chronic.parse("2018-01-01 11am")),
          ],
          Date.parse("2018-01-02") => [
            event_factory("1:1", Chronic.parse("2018-01-02 9am")..Chronic.parse("2018-01-02 12pm")),
          ],
          Date.parse("2018-01-03") => [
            event_factory("1:1", Chronic.parse("2018-01-02 9am")..Chronic.parse("2018-01-02 10am")),
          ],
          Date.parse("2018-01-04") => [
            event_factory("2:0", Chronic.parse("2018-01-01 8am")..Chronic.parse("2018-01-01 10am")),
            event_factory("2:1", Chronic.parse("2018-01-01 12pm")..Chronic.parse("2018-01-01 2pm")),
            event_factory("2:2", Chronic.parse("2018-01-01 4pm")..Chronic.parse("2018-01-01 6pm")),
          ]
        }
      end

      let(:events2)  do
        {
          Date.parse("2018-01-01") => [
            event_factory("1:0", Chronic.parse("2018-01-01 10am")..Chronic.parse("2018-01-01 12pm")),
          ],
          Date.parse("2018-01-02") => [
            event_factory("1:1", Chronic.parse("2018-01-02 9:15am")..Chronic.parse("2018-01-02 9:45am")),
            event_factory("1:1", Chronic.parse("2018-01-02 10am")..Chronic.parse("2018-01-02 11am")),
            event_factory("1:1", Chronic.parse("2018-01-02 11:15am")..Chronic.parse("2018-01-02 11:45am")),
            event_factory("1:1", Chronic.parse("2018-01-02 12:15pm")..Chronic.parse("2018-01-02 1pm")),
          ],
          Date.parse("2018-01-03") => [
            event_factory("1:1", Chronic.parse("2018-01-02 9am")..Chronic.parse("2018-01-02 10am")),
          ],
          Date.parse("2018-01-04") => [
            event_factory("1:0", Chronic.parse("2018-01-01 9am")..Chronic.parse("2018-01-01 11am")),
            event_factory("1:1", Chronic.parse("2018-01-01 1pm")..Chronic.parse("2018-01-01 3pm")),
            event_factory("1:2", Chronic.parse("2018-01-01 5pm")..Chronic.parse("2018-01-01 7pm")),
          ]
        }
      end

      let(:expected_events)  do
        {
          Date.parse("2018-01-01") => [
            event_factory("1:0", Chronic.parse("2018-01-01 10am")..Chronic.parse("2018-01-01 11am")),
          ],
          Date.parse("2018-01-02") => [
            event_factory("1:1", Chronic.parse("2018-01-02 9:15am")..Chronic.parse("2018-01-02 9:45am")),
            event_factory("1:1", Chronic.parse("2018-01-02 10am")..Chronic.parse("2018-01-02 11am")),
            event_factory("1:1", Chronic.parse("2018-01-02 11:15am")..Chronic.parse("2018-01-02 11:45am")),
          ],
          Date.parse("2018-01-03") => [
            event_factory("1:1", Chronic.parse("2018-01-02 9am")..Chronic.parse("2018-01-02 10am")),
          ],
          Date.parse("2018-01-04") => [
            event_factory("", Chronic.parse("2018-01-01 9am")..Chronic.parse("2018-01-01 10am")),
            event_factory("", Chronic.parse("2018-01-01 1pm")..Chronic.parse("2018-01-01 2pm")),
            event_factory("", Chronic.parse("2018-01-01 5pm")..Chronic.parse("2018-01-01 6pm")),
          ]
        }
      end

      it { expect_to_match_expected_events set1.intersection(set2).events }
      it { expect_to_match_expected_events set2.intersection(set1).events }
    end

    context "sets in different time zones" do
      let(:time_zone1) { "America/New_York" }
      let(:time_zone2) { "America/Los_Angeles" }

      let(:events1) do
        in_tz time_zone1 do
          {
            Date.parse("2018-01-01") => [
              event_factory("1:0", Chronic.parse("2018-01-01 12pm")..Chronic.parse("2018-01-01 2pm")),
              event_factory("1:1", Chronic.parse("2018-01-01 4pm")..Chronic.parse("2018-01-01 6pm")),
              event_factory("1:2", Chronic.parse("2018-01-01 8pm")..Chronic.parse("2018-01-01 10pm")),
            ]
          }
        end
      end
      let(:events2) do
        in_tz time_zone2 do
          {
            Date.parse("2018-01-01") => [
              event_factory("2:0", Chronic.parse("2018-01-01 8am")..Chronic.parse("2018-01-01 10am")),
              event_factory("2:1", Chronic.parse("2018-01-01 12pm")..Chronic.parse("2018-01-01 2pm")),
              event_factory("2:2", Chronic.parse("2018-01-01 4pm")..Chronic.parse("2018-01-01 6pm")),
            ]
          }
        end
      end

      context "from the POV of calendar 1" do
        let(:expected_events) do
          in_tz time_zone1 do
            {
              Date.parse("2018-01-01") => [
                event_factory("", Chronic.parse("2018-01-01 12pm")..Chronic.parse("2018-01-01 1pm")),
                event_factory("", Chronic.parse("2018-01-01 4pm")..Chronic.parse("2018-01-01 5pm")),
                event_factory("", Chronic.parse("2018-01-01 8pm")..Chronic.parse("2018-01-01 9pm")),
              ]
            }
          end
        end
        it { expect_to_match_expected_events set1.intersection(set2).events }
      end

      context "from the POV of calendar 2" do
        let(:expected_events) do
          in_tz time_zone2 do
            {
              Date.parse("2018-01-01") => [
                event_factory("", Chronic.parse("2018-01-01 9am")..Chronic.parse("2018-01-01 10am")),
                event_factory("", Chronic.parse("2018-01-01 1pm")..Chronic.parse("2018-01-01 2pm")),
                event_factory("", Chronic.parse("2018-01-01 5pm")..Chronic.parse("2018-01-01 6pm")),
              ]
            }
          end
        end

        it { expect_to_match_expected_events set2.intersection(set1).events }
      end
    end
  end
end
