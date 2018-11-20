describe CalendarAssistant::Scheduler do
  describe "#initialize" do
    it "needs a test"
  end

  describe "#available_blocks" do
    set_date_to_a_weekday # because otherwise if tests run on a weekend they'll fail

    let(:scheduler) { described_class.new ca, er }
    let(:config) { CalendarAssistant::Config.new options: config_options }
    let(:config_options) { Hash.new }
    let(:ca) { CalendarAssistant.new config }
    let(:authorizer) { instance_double("Authorizer") }
    let(:service) { instance_double("CalendarService") }
    let(:calendar) { instance_double("Calendar") }
    let(:time_zone) { ENV['TZ'] }
    let(:calendar_id) { CalendarAssistant::Config::DEFAULT_CALENDAR_ID }
    let(:er) { CalendarAssistant::EventRepository.new service, calendar_id }
    let(:event_set) { CalendarAssistant::EventSet.new er, events }

    before do
      allow(CalendarAssistant::Authorizer).to receive(:new).and_return(authorizer)
      allow(authorizer).to receive(:service).and_return(service)
      allow(service).to receive(:get_calendar).and_return(calendar)
      allow(calendar).to receive(:time_zone).and_return(time_zone)
      allow(config).to receive(:profile_name).and_return("profile-name")

      expect(er).to receive(:find).with(time_range).and_return(event_set)
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
          [
            event_factory("zeroth", Chronic.parse("7:30am")..(Chronic.parse("8am")), :response_status => CalendarAssistant::Event::Response::ACCEPTED),
            event_factory("first", Chronic.parse("8:30am")..(Chronic.parse("10am")), :response_status => CalendarAssistant::Event::Response::ACCEPTED),
            event_factory("second", Chronic.parse("10:30am")..(Chronic.parse("12pm")), :response_status => CalendarAssistant::Event::Response::ACCEPTED),
            event_factory("third", Chronic.parse("1:30pm")..(Chronic.parse("2:30pm")), :response_status => CalendarAssistant::Event::Response::ACCEPTED),
            event_factory("fourth", Chronic.parse("3pm")..(Chronic.parse("5pm")), :response_status => CalendarAssistant::Event::Response::ACCEPTED),
            event_factory("fifth", Chronic.parse("5:30pm")..(Chronic.parse("6pm")), :response_status => CalendarAssistant::Event::Response::ACCEPTED),
            event_factory("sixth", Chronic.parse("6:30pm")..(Chronic.parse("7pm")), :response_status => CalendarAssistant::Event::Response::ACCEPTED),
          ]
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

        it "returns a hash of date => chunks-of-free-time-longer-than-min-duration" do
          expect_to_match_expected_avails scheduler.available_blocks(time_range).events
        end

        it "is in the calendar's time zone" do
          expect(scheduler.available_blocks(time_range).events[date].first.start_time.time_zone.name).to eq(time_zone)
        end

        context "some meetings haven't been accepted" do
          before do
            allow(events[2]).to receive(:response_status).and_return(CalendarAssistant::Event::Response::DECLINED)
          end

          let(:expected_avails) do
            {
              date => [
                event_factory("available", Chronic.parse("10am")..Chronic.parse("1:30pm")),
                event_factory("available", Chronic.parse("2:30pm")..Chronic.parse("3pm")),
                event_factory("available", Chronic.parse("5pm")..Chronic.parse("5:30pm")),
              ]
            }
          end

          it "ignores meetings that are not accepted" do
            expect_to_match_expected_avails scheduler.available_blocks(time_range).events
          end
        end

        context "some meetings are private" do
          before do
            allow(events[2]).to receive(:response_status).and_return(CalendarAssistant::Event::Response::DECLINED) # undo fixture setting
            allow(events[2]).to receive(:private?).and_return(true) # apply new fixture setting
          end

          it "treats private meetings as accepted" do
            expect_to_match_expected_avails scheduler.available_blocks(time_range).events
          end
        end

        context "some meetings are with only myself" do
          before do
            allow(events[2]).to receive(:response_status).and_return(CalendarAssistant::Event::Response::SELF)
          end

          it "treats self meetings as accepted" do
            expect_to_match_expected_avails scheduler.available_blocks(time_range).events
          end
        end
      end

      context "single date with no event at the end of the day" do
        let(:time_range) { CalendarAssistant::CLIHelpers.parse_datespec "today" }
        let(:date) { time_range.first.to_date }

        let(:events) do
          [
            event_factory("first", Chronic.parse("8:30am")..(Chronic.parse("10am")), :response_status => CalendarAssistant::Event::Response::ACCEPTED),
            event_factory("second", Chronic.parse("10:30am")..(Chronic.parse("12pm")), :response_status => CalendarAssistant::Event::Response::ACCEPTED),
            event_factory("third", Chronic.parse("1:30pm")..(Chronic.parse("2:30pm")), :response_status => CalendarAssistant::Event::Response::ACCEPTED),
            event_factory("fourth", Chronic.parse("3pm")..(Chronic.parse("5pm")), :response_status => CalendarAssistant::Event::Response::ACCEPTED),
          ]
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
          expect_to_match_expected_avails scheduler.available_blocks(time_range).events
        end
      end

      context "completely free day with no events" do
        let(:time_range) { CalendarAssistant::CLIHelpers.parse_datespec "today" }
        let(:date) { time_range.first.to_date }

        let(:events) { [] }
        let(:expected_avails) do
          {
            date => [
              event_factory("available", Chronic.parse("9am")..Chronic.parse("6pm")),
            ]
          }
        end

        it "returns a big fat available block" do
          expect_to_match_expected_avails scheduler.available_blocks(time_range).events
        end
      end

      context "with end dates out of order" do
        # see https://github.com/flavorjones/calendar-assistant/issues/44 item 3
        let(:events) do
          [
            event_factory("zeroth", Chronic.parse("11am")..(Chronic.parse("12pm")), :response_status => CalendarAssistant::Event::Response::ACCEPTED),
            event_factory("first", Chronic.parse("11am")..(Chronic.parse("11:30am")), :response_status => CalendarAssistant::Event::Response::ACCEPTED),
          ]
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
          expect_to_match_expected_avails scheduler.available_blocks(time_range).events
        end
      end

      context "with an event that crosses end-of-day" do
        # see https://github.com/flavorjones/calendar-assistant/issues/44 item 4
        let(:events) do
          [
            event_factory("zeroth", Chronic.parse("11am")..(Chronic.parse("12pm")), :response_status => CalendarAssistant::Event::Response::ACCEPTED),
            event_factory("first", Chronic.parse("5pm")..(Chronic.parse("7pm")), :response_status => CalendarAssistant::Event::Response::ACCEPTED),
          ]
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
          expect_to_match_expected_avails scheduler.available_blocks(time_range).events
        end
      end
    end

    describe "multiple days" do
      let(:time_range) { CalendarAssistant::CLIHelpers.parse_datespec "2018-01-01..2018-01-03" }
      let(:events) { [] }
      let(:expected_avails) do
        {
          Date.parse("2018-01-01") => [event_factory("available", Chronic.parse("2018-01-01 9am")..Chronic.parse("2018-01-01 6pm"))],
          Date.parse("2018-01-02") => [event_factory("available", Chronic.parse("2018-01-02 9am")..Chronic.parse("2018-01-02 6pm"))],
          Date.parse("2018-01-03") => [event_factory("available", Chronic.parse("2018-01-03 9am")..Chronic.parse("2018-01-03 6pm"))],
        }
      end

      it "returns a hash of all dates" do
        found_avails = scheduler.available_blocks(time_range).events

        expect_to_match_expected_avails found_avails
      end
    end

    describe "configurable parameters" do
      let(:time_range) { in_tz { CalendarAssistant::CLIHelpers.parse_datespec "today" } }
      let(:date) { in_tz { time_range.first.to_date } }

      let(:events) do
        in_tz do
          [
            event_factory("first", Chronic.parse("8:30am")..(Chronic.parse("10am")), :response_status => CalendarAssistant::Event::Response::ACCEPTED),
            event_factory("second", Chronic.parse("10:30am")..(Chronic.parse("12pm")), :response_status => CalendarAssistant::Event::Response::ACCEPTED),
            event_factory("third", Chronic.parse("1:30pm")..(Chronic.parse("2:30pm")), :response_status => CalendarAssistant::Event::Response::ACCEPTED),
            event_factory("fourth", Chronic.parse("3pm")..(Chronic.parse("5pm")), :response_status => CalendarAssistant::Event::Response::ACCEPTED),
            event_factory("fifth", Chronic.parse("5:30pm")..(Chronic.parse("6pm")), :response_status => CalendarAssistant::Event::Response::ACCEPTED),
            event_factory("fourth", Chronic.parse("6:30pm")..(Chronic.parse("7pm")), :response_status => CalendarAssistant::Event::Response::ACCEPTED),
          ]
        end
      end

      describe "meeting-length" do
        context "30m" do
          let(:config_options) { {CalendarAssistant::Config::Keys::Settings::MEETING_LENGTH => "30m"} }

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
            expect_to_match_expected_avails scheduler.available_blocks(time_range).events
          end
        end

        context "60m" do
          let(:config_options) { {CalendarAssistant::Config::Keys::Settings::MEETING_LENGTH => "60m"} }

          let(:expected_avails) do
            {
              date => [
                event_factory("available", Chronic.parse("12pm")..Chronic.parse("1:30pm")),
              ]
            }
          end

          it "finds blocks of time 60m or longer" do
            expect_to_match_expected_avails scheduler.available_blocks(time_range).events
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
            expect_to_match_expected_avails scheduler.available_blocks(time_range).events
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
            expect_to_match_expected_avails scheduler.available_blocks(time_range).events
          end
        end
      end

      context "EventRepository calendar is different from own time zone" do
        let(:time_zone) { "America/New_York" }
        let(:other_calendar) { instance_double("Calendar") }
        let(:other_time_zone) { "America/Los_Angeles" }

        before do
          allow(er).to receive(:calendar).and_return(other_calendar)
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
          expect_to_match_expected_avails scheduler.available_blocks(time_range).events
        end

        it "is in the other calendar's time zone" do
          expect(scheduler.available_blocks(time_range).events[date].first.start_time.time_zone.name).to eq(other_time_zone)
        end
      end
    end
  end

  describe "#available_block" do
    it "needs a test" # and maybe should not even be in this class - maybe EventRepository instead?
  end
end
