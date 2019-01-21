describe CalendarAssistant::Scheduler do
  describe "class methods" do
    describe ".select_busy_events" do
      let(:raw_events) do
        event_list_factory do
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
              {start: "2018-01-07", end: "2018-01-09", summary: "this is an all day busy event", options: [:all_day, :busy] }
          ]
        end
      end

      let(:cooked_events) do
        event_list_factory do
          {
              Date.parse("2018-01-01") => [
                  {start: "2018-01-01 9am", end: "2018-01-01 10am", summary: "accepted", options: :accepted},
                  {start: "2018-01-01 9am", end: "2018-01-01 10am", summary: "self", options: :self},
                  {start: "2018-01-01 9am", end: "2018-01-01 10am", summary: "private", options: :private}
              ],
              Date.parse("2018-01-02") => [
                  {start: "2018-01-02 9am", end: "2018-01-02 10am", summary: "yeah", options: :self}
              ],
              Date.parse("2018-01-03") => [
                  {start: "2018-01-03 9am", end: "2018-01-03 10am", summary: "sure", options: :self}
              ],
              Date.parse("2018-01-07") => [
                  {start: "2018-01-07", end: "2018-01-09", summary: "this is an all day busy event", options: [:all_day, :busy] }
              ]

          }
        end
      end

      def expect_event_equalish e1, e2
        expect(e1.summary).to eq(e2.summary)
        expect(e1.start_time).to eq(e2.start_time)
        expect(e1.end_time).to eq(e2.end_time)
      end

      def expect_event_set_hash_equalish es1, es2
        expect(es1.keys).to eq(es2.keys)
        es1.keys.each do |date|
          es1[date].each_with_index do |e, j|
            expect_event_equalish e, es2[date][j]
          end
        end
      end

      it "selects relevant events into a new event set" do
        raw_event_set = CalendarAssistant::EventSet.new instance_double("er"), raw_events
        cooked_event_set = described_class.select_busy_events raw_event_set
        expect_event_set_hash_equalish cooked_events, cooked_event_set.events
      end
    end
  end

  describe "instance methods" do
    let(:scheduler) { described_class.new ca, er }
    let(:config) { CalendarAssistant::Config.new options: config_options }
    let(:config_options) { Hash.new }
    let(:ca) { CalendarAssistant.new config, service: service }
    let(:service) { instance_double("CalendarService") }
    let(:calendar) { instance_double("Calendar") }
    let(:time_zone) { ENV['TZ'] }
    let(:calendar_id) { "foo@example.com" }
    let(:er) { CalendarAssistant::EventRepository.new service, calendar_id }
    let(:er2) { CalendarAssistant::EventRepository.new service, calendar_id }
    let(:event_set) { CalendarAssistant::EventSet.new er, events }
    let(:events) { [] }
    let(:time_range) { CalendarAssistant::CLI::Helpers.parse_datespec "2018-01-01..2018-01-03" }

    before do
      allow(service).to receive(:get_calendar).and_return(calendar)
      allow(calendar).to receive(:time_zone).and_return(time_zone)
      allow(config).to receive(:profile_name).and_return("profile-name")
    end

    describe "#initialize" do
      it "accepts a CalendarAssistant and EventRepository as arguments" do
        scheduler = described_class.new ca, er
        expect(scheduler.ca).to eq(ca)
        expect(scheduler.ers).to eq([er])
      end

      it "accepts a CalendarAssistant and EventRepositories as arguments" do
        scheduler = described_class.new ca, [er, er2]
        expect(scheduler.ca).to eq(ca)
        expect(scheduler.ers).to eq([er, er2])
      end
    end

    describe "#available_blocks" do
      let(:event_set_hash) { CalendarAssistant::EventSet.new er, {} }

      before do
        allow(er).to receive(:find).and_return(event_set)
        allow(described_class).to receive(:select_busy_events).and_return(event_set_hash)
        allow(event_set_hash).to receive(:ensure_keys)
      end

      it "calls EventRepository#find with the right time range" do
        expect(er).to receive(:find).with(time_range).and_return(event_set)
        scheduler.available_blocks(time_range)
      end

      it "calls Scheduler.select_busy_events to filter events" do
        expect(described_class).to receive(:select_busy_events).with(event_set).and_return(event_set_hash)
        scheduler.available_blocks(time_range)
      end

      it "fills in empty dates in the event set" do
        date_range = time_range.first.to_date .. time_range.last.to_date
        expect(event_set_hash).to receive(:ensure_keys).with(date_range, only: true)
        scheduler.available_blocks(time_range)
      end

      it "calls EventSet#available_blocks within a CalendarAssistant#in_env block" do
        available_blocks = instance_double "EventSet(available)"

        expect(ca).to receive(:in_env).and_yield.ordered
        expect(event_set_hash).to receive(:available_blocks).and_return(available_blocks).ordered

        result = scheduler.available_blocks(time_range)
        expect(result).to eq(available_blocks)
      end

      describe "meeting length" do
        context "by default" do
          it "passes the right meeting length to EventSet#available_blocks" do
            length = ChronicDuration.parse CalendarAssistant::Config::DEFAULT_SETTINGS[CalendarAssistant::Config::Keys::Settings::MEETING_LENGTH]
            expect(event_set_hash).to receive(:available_blocks).with(length: length)
            scheduler.available_blocks(time_range)
          end
        end

        context "when configured" do
          let(:config_options) { {CalendarAssistant::Config::Keys::Settings::MEETING_LENGTH => "60m"} }

          it "passes the right meeting length to EventSet#available_blocks" do
            expect(event_set_hash).to receive(:available_blocks).with(length: 60 * 60)
            scheduler.available_blocks(time_range)
          end
        end
      end

      context "multiple calendars" do
        let(:scheduler) { described_class.new ca, [er, er2] }

        before do
          allow(er2).to receive(:find).and_return(event_set)
        end

        it "calls EventRepository#find with the right time range" do
          expect(er).to receive(:find).with(time_range).and_return(event_set)
          expect(er2).to receive(:find).with(time_range).and_return(event_set)
          scheduler.available_blocks(time_range)
        end

        describe "meeting length" do
          context "by default" do
            let(:length) { ChronicDuration.parse(CalendarAssistant::Config::DEFAULT_SETTINGS[CalendarAssistant::Config::Keys::Settings::MEETING_LENGTH]) }

            it "returns the intersection of the available blocks" do
              available_blocks = instance_double "EventSet(available)"
              allow(event_set_hash).to receive(:available_blocks).and_return(available_blocks)
              expect(available_blocks).to receive(:intersection).with(available_blocks, length: length).and_return(available_blocks)
              result = scheduler.available_blocks(time_range)
              expect(result).to eq(available_blocks)
            end
          end

          context "when configured" do
            let(:config_options) { {CalendarAssistant::Config::Keys::Settings::MEETING_LENGTH => "60m"} }

            it "returns the intersection of the available blocks" do
              available_blocks = instance_double "EventSet(available)"
              allow(event_set_hash).to receive(:available_blocks).and_return(available_blocks)
              expect(available_blocks).to receive(:intersection).with(available_blocks, length: 60*60).and_return(available_blocks)
              result = scheduler.available_blocks(time_range)
              expect(result).to eq(available_blocks)
            end
          end
        end
      end
    end
  end
end
