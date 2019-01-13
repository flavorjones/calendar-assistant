describe CalendarAssistant::CLI::EventSetPresenter do

  let(:config) { double }

  describe "#now!" do
    let(:presenter_class) { double(:presenter_class, new: presenter) }
    let(:presenter) { double }

    freeze_time

    let(:event) { CalendarAssistant::Event.new(GCal::Event.new start: GCal::EventDateTime.new(date_time: start_time)) }
    let(:now) { instance_double("Event<now>") }
    let(:out) { StringIO.new }

    subject { described_class.new(double, config: config, event_presenter_class: presenter_class) }

    before do
      allow(CalendarAssistant::CLI::Helpers).to receive(:now).and_return(now)
    end

    context "having not printed yet" do
      let(:printed) { false }

      context "event start time is earlier than now" do
        let(:start_time) { Time.now - 1.minute }

        it "does not print and returns false" do
          expect(presenter).not_to receive(:description)
          rval = subject.now!(event, printed, out: out, presenter_class: presenter_class)
          expect(rval).to be_falsey
        end
      end

      context "event start time is later than now but on a different day" do
        let(:start_time) { Time.now + 1.day + 1.minute }

        it "does not print and returns false" do
          expect(presenter).not_to receive(:description)
          rval = subject.now!(event, printed, out: out, presenter_class: presenter_class)
          expect(rval).to be_falsey
        end
      end

      context "event start time is later than now" do
        let(:start_time) { Time.now + 1.minute }

        it "prints and returns true" do
          expect(presenter_class).to receive(:new).with(now).and_return(presenter)
          expect(presenter).to receive(:description)
          rval = subject.now!(event, printed, out: out, presenter_class: presenter_class)
          expect(rval).to be_truthy
        end
      end
    end

    context "having already printed" do
      let(:printed) { true }

      context "event start time is later than now" do
        let(:start_time) { Time.now + 1.minute }

        it "does not print and returns true" do
          expect(presenter_class).not_to receive(:new).with(now)
          rval = subject.now!(event, printed, out: out, presenter_class: presenter_class)
          expect(rval).to be_truthy
        end
      end
    end
  end

  describe "description" do
    subject { described_class.new(event_set, config: config, event_presenter_class: event_presenter_class) }

    let(:event_presenter_class) { double(:event_presenter_class, new: event_presenter) }
    let(:event_presenter) { double(:event_presenter, description: "event-presenter-description") }
    let(:calendar) { instance_double("Calendar") }
    let(:calendar_id) { "calendar-id" }
    let(:calendar_time_zone) { "calendar/time/zone" }
    let(:er) { instance_double("EventRepository") }
    let(:title_regexp) { Regexp.new("#{calendar_id}.*#{calendar_time_zone}") }
    let(:config) { CalendarAssistant::CLI::Config.new options: config_options }
    let(:config_options) { Hash.new }

    let(:events) do
      event_list_factory do
        [
            {start: "2001-01-01", summary: "do a thing"},
            {start: "2001-01-01", summary: "do another thing"},
        ]
      end
    end

    let(:event) { events.first }

    before do
      allow(calendar).to receive(:id).and_return(calendar_id)
      allow(calendar).to receive(:time_zone).and_return(calendar_time_zone)
      allow(er).to receive(:calendar).and_return(calendar)
    end

    context "passed a single Event" do
      let(:event_set) { CalendarAssistant::EventSet.new(er, event) }

      it "prints a title containing the cal id and time zone" do
        expect(subject.to_s).to match(title_regexp)
      end

      it "prints the event description" do
        expect(event_presenter_class).to receive(:new).and_return(event_presenter)
        expect(subject.to_s).to match /event-presenter-description/
      end
    end

    context "passed an Array of Events" do
      let(:event_set) { CalendarAssistant::EventSet.new(er, events) }

      it "prints a title containing the cal id and time zone" do
        expect(subject.to_s).to match(title_regexp)
      end

      it "calls #print_now! before each event" do
        expect(subject).to receive(:now!).exactly(events.length).times
        subject.to_s
      end

      it "calls puts with event descriptions for each Event" do
        events.each do |event|
          expect(event_presenter_class).to receive(:new).and_return(event_presenter)
          expect(event_presenter).to receive(:description).and_return(event.summary)
        end
        subject.to_s
      end

      context "option 'commitments'" do

        let(:config_options) { {CalendarAssistant::Config::Keys::Options::COMMITMENTS => true} }

        it "omits events that are not a commitment" do
          allow(events.first).to receive(:commitment?).and_return(true)
          allow(events.last).to receive(:commitment?).and_return(false)

          expect(event_presenter_class).to receive(:new).with(events.first)
          expect(event_presenter_class).not_to receive(:new).with(events.last)

          subject.description
        end
      end

      context "the array is empty" do
        let(:event_set) { CalendarAssistant::EventSet.new(er, []) }

        it "prints a standard message" do
          expect(subject.description).to match /No events in this time range.\n$/
        end
      end

      context "the array is nil" do
        let(:event_set) { CalendarAssistant::EventSet.new(er, nil) }
        it "prints a standard message" do
          expect(subject.description).to match /No events in this time range.\n$/
        end
      end
    end

    context "passed a Hash of Arrays of Events" do
      let(:event_set) { CalendarAssistant::EventSet.new(er, {first: [events.first], second: [events.second]}) }

      it "prints a title containing the cal id and time zone" do
        expect(subject.to_s).to match(title_regexp)
      end


      it "prints each hash key capitalized" do
        expect(subject.description).to match /First:/
        expect(subject.description).to match /Second:/
      end

      let(:event_set) { CalendarAssistant::EventSet.new(er, {first: [events.first], second: [events.second]}) }

      it "recursively creates an event set presenter for each hash value" do
        allow(described_class).to receive(:new).and_call_original

        expect(described_class).to receive(:new).with(CalendarAssistant::EventSet.new(er, [events.first]), config: config, event_presenter_class: event_presenter_class)
        expect(described_class).to receive(:new).with(CalendarAssistant::EventSet.new(er, [events.second]), config: config, event_presenter_class: event_presenter_class)
        subject.to_s
      end
    end
  end
end