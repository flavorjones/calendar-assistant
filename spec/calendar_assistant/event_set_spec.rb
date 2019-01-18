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
      let(:time_range) { CalendarAssistant::CLI::Helpers.parse_datespec "today" }
      let(:date) { time_range.first.to_date }

      context "with an event at the end of the day and other events later" do
        let(:events) do
          event_list_factory_in_hash do
            {
                date => [
                    {start: "7:30am", end: "8am", summary: "zeroth"},
                    {start: "8:30am", end: "10am", summary: "first"},
                    {start: "10:30am", end: "12pm", summary: "second"},
                    {start: "1:30pm", end: "2:30pm", summary: "third"},
                    {start: "3pm", end: "5pm", summary: "fourth"},
                    {start: "5:30pm", end: "6pm", summary: "fifth"},
                    {start: "6:30pm", end: "7pm", summary: "sixth"}
                ]
            }
          end
        end

        let(:expected_events) do
          event_list_factory_in_hash do
              {
                date => [
                  {start: "10am", end: "10:30am", summary: "available"},
                  {start: "12pm", end: "1:30pm", summary: "available"},
                  {start: "2:30pm", end: "3pm", summary: "available"},
                  {start: "5pm", end: "5:30pm", summary: "available"},
                ]
              }
          end
        end

        it "returns an EventSet storing a hash of available blocks on each date" do
          expect_to_match_expected_events subject.available_blocks.events
        end

        it "is in the calendar's time zone" do
          expected_tz = in_tz(time_zone) { Time.zone.now.to_datetime.strftime("%Z") }
          expect(subject.available_blocks.events[date].first.start_time.strftime("%Z")).to eq(expected_tz)
        end

        context "a meeting length is passed" do
          let(:expected_events) do
            event_list_factory_in_hash do
              {
                  date => [
                      {start: "12pm", end: "1:30pm", summary: "available"},
                  ]
              }
            end
          end

          it "ignores available blocks shorter than that length" do
            expect_to_match_expected_events subject.available_blocks(length: 31.minutes).events
          end
        end
      end

      context "single date with no event at the end of the day" do
        let(:time_range) { CalendarAssistant::CLI::Helpers.parse_datespec "today" }
        let(:date) { time_range.first.to_date }

        let(:events) do
          event_list_factory_in_hash do
            {
                date => [
                    {start: "8:30am", end: "10am", summary: "first"},
                    {start: "10:30am", end: "12pm", summary: "second"},
                    {start: "1:30pm", end: "2:30pm", summary: "third"},
                    {start: "3pm", end: "5pm", summary: "fourth"},
                ]
            }
          end
        end

        let(:expected_events) do
          event_list_factory_in_hash do
              {
                date => [
                  {start: "10am", end: "10:30am", summary: "available"},
                  {start: "12pm", end: "1:30pm", summary: "available"},
                  {start: "2:30pm", end: "3pm", summary: "available"},
                  {start: "5pm", end: "6pm", summary: "available"},
                ]
              }
          end
        end

        it "finds chunks of free time at the end of the day" do
          expect_to_match_expected_events subject.available_blocks.events
        end
      end

      context "completely free day with no events" do
        let(:time_range) { CalendarAssistant::CLI::Helpers.parse_datespec "today" }
        let(:date) { time_range.first.to_date }

        let(:events) { {date => []} }
        let(:expected_events) do
          event_list_factory_in_hash do
            {
                date => [
                    {start: "9am", end: "6pm", summary: "available"},
                ]
            }
          end
        end

        it "returns a big fat available block" do
          expect_to_match_expected_events subject.available_blocks.events
        end
      end

      context "with end dates out of order" do
        # see https://github.com/flavorjones/calendar-assistant/issues/44 item 3
        let(:events) do
          event_list_factory_in_hash do
            {
                date => [
                    {start: "11am", end: "12pm", summary: "zeroth"},
                    {start: "11am", end: "11:30am", summary: "first"},
                ]
            }
          end
        end

        let(:expected_events) do
          event_list_factory_in_hash do
              {
                date => [
                  {start: "9am", end: "11am", summary: "available"},
                  {start: "12pm", end: "6pm", summary: "available"},
                ]
              }
          end
        end

        it "returns correct available blocks" do
          expect_to_match_expected_events subject.available_blocks.events
        end
      end

      context "with an event that crosses end-of-day" do
        # see https://github.com/flavorjones/calendar-assistant/issues/44 item 4
        let(:events) do
          event_list_factory_in_hash do
            {
                date => [
                    {start: "11am", end: "12pm", summary: "zeroth"},
                    {start: "5pm", end: "7pm", summary: "first"},
                ]
            }
          end
        end

        let(:expected_events) do
          event_list_factory_in_hash do
              {
                date => [
                  {start: "9am", end: "11am", summary: "available"},
                  {start: "12pm", end: "5pm", summary: "available"},
                ]
              }
          end
        end

        it "returns correct available blocks" do
          expect_to_match_expected_events subject.available_blocks.events
        end
      end
    end

    describe "multiple days" do
      let(:time_range) { CalendarAssistant::CLI::Helpers.parse_datespec "2018-01-01..2018-01-03" }
      let(:events) do
        event_list_factory_in_hash do
          {
              Date.parse("2018-01-01") => [],
              Date.parse("2018-01-02") => [],
              Date.parse("2018-01-03") => [],
          }
        end
      end
      let(:expected_events) do
        event_list_factory_in_hash do
            {
              Date.parse("2018-01-01") => [{start: "2018-01-01 9am", end: "2018-01-01 6pm", summary: "available"}],
              Date.parse("2018-01-02") => [{start: "2018-01-02 9am", end: "2018-01-02 6pm", summary: "available"}],
              Date.parse("2018-01-03") => [{start: "2018-01-03 9am", end: "2018-01-03 6pm", summary: "available"}],
            }
        end
      end

      it "returns a hash of all dates" do
        expect_to_match_expected_events subject.available_blocks.events
      end
    end

    describe "configurable parameters" do
      let(:time_range) { in_tz { CalendarAssistant::CLI::Helpers.parse_datespec "today" } }
      let(:date) { in_tz { time_range.first.to_date } }

      let(:events) do
        in_tz do
          event_list_factory_in_hash do
            {
                date => [
                    {start: "8:30am", end: "10am", summary: "first"},
                    {start: "10:30am", end: "12pm", summary: "second"},
                    {start: "1:30pm", end: "2:30pm", summary: "third"},
                    {start: "3pm", end: "5pm", summary: "fourth"},
                    {start: "5:30pm", end: "6pm", summary: "fifth"},
                    {start: "6:30pm", end: "7pm", summary: "fourth"},
                ]
            }
          end
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
            event_list_factory_in_hash do
              {
                  date => [
                      {start: "10am", end: "10:30am", summary: "available"},
                      {start: "12pm", end: "1:30pm", summary: "available"},
                      {start: "2:30pm", end: "3pm", summary: "available"},
                      {start: "5pm", end: "5:30pm", summary: "available"},
                  ]
              }
            end
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
            event_list_factory_in_hash do
              {
                  date => [
                      {start: "8am", end: "8:30am", summary: "available"},
                      {start: "10am", end: "10:30am", summary: "available"},
                      {start: "12pm", end: "1:30pm", summary: "available"},
                      {start: "2:30pm", end: "3pm", summary: "available"},
                      {start: "5pm", end: "5:30pm", summary: "available"},
                      {start: "6pm", end: "6:30pm", summary: "available"},
                  ]
              }
            end
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
            event_list_factory_in_hash do
              {
                  date => [
                      {start: "12pm", end: "1:30pm", summary: "available"},
                      {start: "2:30pm", end: "3pm", summary: "available"},
                      {start: "5pm", end: "5:30pm", summary: "available"},
                      {start: "6pm", end: "6:30pm", summary: "available"},
                      {start: "7pm", end: "9pm", summary: "available"},
                  ]
              }
            end
          end
        end

        it "returns the free blocks in that time zone" do
          expect_to_match_expected_events subject.available_blocks.events
        end

        it "is in the other calendar's time zone" do
          expected_tz = in_tz(other_time_zone) { Time.zone.now.to_datetime.strftime("%Z") }
          expect(subject.available_blocks.events[date].first.start_time.strftime("%Z")).to eq(expected_tz)
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
      let(:events1) do
        event_list_factory_in_hash do
          {
              Date.parse("2018-01-01") => [
                  {start: "2018-01-01 9am", end: "2018-01-01 11am", summary: "1:0"},
              ]
          }
        end
      end

      let(:events2) do
        event_list_factory_in_hash do
          {
              Date.parse("2018-01-01") => [
                  {start: "2018-01-01 11am", end: "2018-01-01 2pm", summary: "1:0"},
              ]
          }
        end
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
      let(:events1) do
        event_list_factory_in_hash do
          {
              Date.parse("2018-01-01") => [
                  {start: "2018-01-01 9am", end: "2018-01-01 11am", summary: "1:0"},
              ],
              Date.parse("2018-01-02") => [
                  {start: "2018-01-02 9am", end: "2018-01-02 12pm", summary: "1:1"},
              ],
              Date.parse("2018-01-03") => [
                  {start: "2018-01-02 9am", end: "2018-01-02 10am", summary: "1:1"},
              ],
              Date.parse("2018-01-04") => [
                  {start: "2018-01-01 8am", end: "2018-01-01 10am", summary: "2:0"},
                  {start: "2018-01-01 12pm", end: "2018-01-01 2pm", summary: "2:1"},
                  {start: "2018-01-01 4pm", end: "2018-01-01 6pm", summary: "2:2"},
              ]
          }
        end
      end

      let(:events2) do
        event_list_factory_in_hash do
          {
              Date.parse("2018-01-01") => [
                  {start: "2018-01-01 10am", end: "2018-01-01 12pm", summary: "1:0"},
              ],
              Date.parse("2018-01-02") => [
                  {start: "2018-01-02 9:15am", end: "2018-01-02 9:30am", summary: "1:1"},
                  {start: "2018-01-02 10am", end: "2018-01-02 11am", summary: "1:1"},
                  {start: "2018-01-02 11:15am", end: "2018-01-02 11:45am", summary: "1:1"},
                  {start: "2018-01-02 12:15pm", end: "2018-01-02 1pm", summary: "1:1"},
              ],
              Date.parse("2018-01-03") => [
                  {start: "2018-01-02 9am", end: "2018-01-02 10am", summary: "1:1"},
              ],
              Date.parse("2018-01-04") => [
                  {start: "2018-01-01 9am", end: "2018-01-01 11am", summary: "1:0"},
                  {start: "2018-01-01 1pm", end: "2018-01-01 3pm", summary: "1:1"},
                  {start: "2018-01-01 5pm", end: "2018-01-01 7pm", summary: "1:2"},
              ]
          }
        end
      end

      context "with no min-length specified" do
        let(:expected_events) do
          event_list_factory_in_hash do
            {
                Date.parse("2018-01-01") => [
                    {start: "2018-01-01 10am", end: "2018-01-01 11am", summary: "1:0"},
                ],
                Date.parse("2018-01-02") => [
                    {start: "2018-01-02 9:15am", end: "2018-01-02 9:30am", summary: "1:1"},
                    {start: "2018-01-02 10am", end: "2018-01-02 11am", summary: "1:1"},
                    {start: "2018-01-02 11:15am", end: "2018-01-02 11:45am", summary: "1:1"},
                ],
                Date.parse("2018-01-03") => [
                    {start: "2018-01-02 9am", end: "2018-01-02 10am", summary: "1:1"},
                ],
                Date.parse("2018-01-04") => [
                    {start: "2018-01-01 9am", end: "2018-01-01 10am", summary: ""},
                    {start: "2018-01-01 1pm", end: "2018-01-01 2pm", summary: ""},
                    {start: "2018-01-01 5pm", end: "2018-01-01 6pm", summary: ""},
                ]
            }
          end
        end

        it { expect_to_match_expected_events set1.intersection(set2).events }
        it { expect_to_match_expected_events set2.intersection(set1).events }
      end

      context "with a min-length specified" do
        let(:expected_events) do
          event_list_factory_in_hash do
            {
                Date.parse("2018-01-01") => [
                    {start: "2018-01-01 10am", end: "2018-01-01 11am", summary: "1:0"},
                ],
                Date.parse("2018-01-02") => [
                    {start: "2018-01-02 10am", end: "2018-01-02 11am", summary: "1:1"},
                ],
                Date.parse("2018-01-03") => [
                    {start: "2018-01-02 9am", end: "2018-01-02 10am", summary: "1:1"},
                ],
                Date.parse("2018-01-04") => [
                    {start: "2018-01-01 9am", end: "2018-01-01 10am", summary: ""},
                    {start: "2018-01-01 1pm", end: "2018-01-01 2pm", summary: ""},
                    {start: "2018-01-01 5pm", end: "2018-01-01 6pm", summary: ""},
                ]
            }
          end
        end

        it { expect_to_match_expected_events set1.intersection(set2, length: 31.minutes).events }
        it { expect_to_match_expected_events set2.intersection(set1, length: 31.minutes).events }
      end
    end

    context "sets in different time zones" do
      let(:time_zone1) { "America/New_York" }
      let(:time_zone2) { "America/Los_Angeles" }

      let(:events1) do
        in_tz time_zone1 do
          event_list_factory_in_hash do
            {
                Date.parse("2018-01-01") => [
                    {start: "2018-01-01 12pm", end: "2018-01-01 2pm", summary: "1:0"},
                    {start: "2018-01-01 4pm", end: "2018-01-01 6pm", summary: "1:1"},
                    {start: "2018-01-01 8pm", end: "2018-01-01 10pm", summary: "1:2"},
                ]
            }
          end
        end
      end
      let(:events2) do
        in_tz time_zone2 do
          event_list_factory_in_hash do
            {
                Date.parse("2018-01-01") => [
                    {start: "2018-01-01 8am", end: "2018-01-01 10am", summary: "2:0"},
                    {start: "2018-01-01 12pm", end: "2018-01-01 2pm", summary: "2:1"},
                    {start: "2018-01-01 4pm", end: "2018-01-01 6pm", summary: "2:2"},
                ]
            }
          end
        end
      end


      context "from the POV of calendar 1" do
        let(:expected_events) do
          in_tz time_zone1 do
            event_list_factory_in_hash do
              {
                  Date.parse("2018-01-01") => [
                      {start: "2018-01-01 12pm", end: "2018-01-01 1pm", summary: ""},
                      {start: "2018-01-01 4pm", end: "2018-01-01 5pm", summary: ""},
                      {start: "2018-01-01 8pm", end: "2018-01-01 9pm", summary: ""},
                  ]
              }
            end
          end
        end
        it { expect_to_match_expected_events set1.intersection(set2).events }
      end

      context "from the POV of calendar 2" do
        let(:expected_events) do
          in_tz time_zone2 do
            event_list_factory_in_hash do
              {
                  Date.parse("2018-01-01") => [
                      {start: "2018-01-01 9am", end: "2018-01-01 10am", summary: ""},
                      {start: "2018-01-01 1pm", end: "2018-01-01 2pm", summary: ""},
                      {start: "2018-01-01 5pm", end: "2018-01-01 6pm", summary: ""},
                  ]
              }
            end
          end
        end

        it { expect_to_match_expected_events set2.intersection(set1).events }
      end
    end
  end
end
