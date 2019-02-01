require 'date'

describe CalendarAssistant::EventRepository do

  let(:service) { CalendarAssistant::LocalService.new }

  let(:event_repository) { described_class.new(service, calendar_id) }
  let(:calendar_id) { CalendarAssistant::Config::DEFAULT_CALENDAR_ID }
  let(:calendar) { GCal::Calendar.new(id: calendar_id) }
  let(:event_array) { [nine_event, nine_thirty_event] }
  let(:event_set) { CalendarAssistant::EventSet.new event_repository, event_array }
  let(:time_range) { Time.parse("2018-10-18")..Time.parse("2018-10-19") }
  let(:nine_event) do
    GCal::Event.new(id: 1,
                    start: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 09:00:00")),
                    end: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 10:00:00")))
  end
  let(:nine_thirty_event) do
    GCal::Event.new(id: 2,
                    start: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 09:30:00")),
                    end: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 10:00:00")))
  end

  before do
    service.insert_calendar(calendar)

    event_array.each do |event|
      service.insert_event(calendar_id, event)
    end
  end

  describe "#initialize" do
    context "when the calendar id exists" do
      it "fetches a Calendar for the stated id" do
        expect(service).to receive(:get_calendar).with(calendar_id).and_return(calendar)
        described_class.new(service, calendar_id)
      end
    end

    context "when a client error occurs" do
      let(:exception) { Google::Apis::ClientError.new("bleep bloop", status_code: status_code) }

      context "and its that the calendar does not exist" do
        let(:status_code) { 404 }
        it "raises a CalendarAssistant::BaseException" do
          expect(service).to receive(:get_calendar).with(calendar_id).and_raise(exception)
          expect {described_class.new(service, calendar_id)}.to raise_error(CalendarAssistant::BaseException)
        end
      end

      context "when some other client error occurs" do
        let(:status_code) { 401 }
        it "raises the original ClientError" do
          expect(service).to receive(:get_calendar).with(calendar_id).and_raise(exception)
          expect {described_class.new(service, calendar_id)}.to raise_error(exception)
        end
      end
    end
  end

  describe "#create and #new" do
    context "#create" do
      it "creates an event" do
        event_repository.create(summary: "boom",
                                start: Date.parse("2018-10-17"),
                                end: Date.parse("2018-10-19"))
        expect(event_repository.find(time_range).events.map(&:summary)).to include("boom")
      end
    end

    context "#new" do
      it "news an event, but does not add it to the repository" do
        event = event_repository.new(summary: "boom",
                                     start: Date.parse("2018-10-17"),
                                     end: Date.parse("2018-10-19"))
        expect(event_repository.find(time_range).events.map(&:summary)).not_to include("boom")
        expect(event).to be_a(CalendarAssistant::Event)
      end
    end
  end

  describe "#find" do
    context "when predicate filters are not passed" do
      it "returns an EventSet with er=>self" do
        result = event_repository.find time_range
        expect(result.event_repository).to eq(event_repository)
      end

      context "given a time range" do
        it "calls CalendarService#list_events with the range" do
          result = event_repository.find time_range
          expect(result.events).to eq(event_array)
        end
      end

      context "when no items are found" do
        let(:time_range) { Time.parse("2017-10-18")..Time.parse("2017-10-19") }

        it "returns an empty array" do
          result = event_repository.find time_range
          expect(result.events).to eq([])
        end
      end
    end

    context "when predicate filters are passed" do
      let(:other_event) do
        GCal::Event.new(id: 3,
                        start: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 10:30:00")),
                        end: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 11:00:00")))
      end

      let(:event_array) { [nine_event, nine_thirty_event, other_event] }

      before do
        allow(nine_event).to receive(:locked?).and_return(false)
        allow(nine_thirty_event).to receive(:locked?).and_return(true )
        allow(other_event).to receive(:locked?).and_return(true)

        allow(nine_event).to receive(:guests_can_modify?).and_return(false)
        allow(nine_thirty_event).to receive(:guests_can_modify?).and_return(false )
        allow(other_event).to receive(:guests_can_modify?).and_return(true)
      end

      context "and the predicate is not valid" do
        it 'raises an error' do
          expect { event_repository.find time_range, predicates: {malicious?: true, object_id: "1"} }.to raise_error(CalendarAssistant::BaseException)
        end
      end

      it "uses those predicates to filter the event set" do
        event_set = event_repository.find time_range, predicates: { locked?: true, guests_can_modify?: false }
        expect(event_set.events.length).to eq 1
        expect(event_set.events.first.__getobj__).to eq nine_thirty_event
      end
    end
  end

  describe "#delete" do
    it "calls the service with the event id" do
      expect(event_repository.delete(nine_event)).to eq nine_event
      result = event_repository.find time_range
      expect(result.events).not_to include(nine_event)
    end
  end

  describe "#update" do
    let(:time_range) { Time.parse("2018-10-18 08:00")..Time.parse("2018-10-18 09:15") }

    it "casts dates to GCal::EventDateTime and updates the event" do
      new_attributes = {start: DateTime.parse("1776-07-04")}
      event_repository.update(nine_event, new_attributes)

      result = event_repository.find time_range
      expect(result.events.first.start.date_time).to eq DateTime.parse("1776-07-04")
    end
  end

  describe "#in_tz" do
    before do
      expect(calendar).to receive(:time_zone).and_return("a time zone id")
    end

    it "calls CalendarAssistant.in_tz with the calendar's time zone" do
      expect(CalendarAssistant).to receive(:in_tz).with("a time zone id")
      event_repository.in_tz do ; end
    end
  end

  describe "#available_block" do
    before do
      allow(calendar).to receive(:time_zone).and_return("America/New_York")
    end

    it "returns a CalendarAssistant::Event" do
      event = event_repository.available_block(Time.now, Time.now)
      expect(event).to be_a(CalendarAssistant::Event)
    end

    context "given DateTime" do
      freeze_time

      it "returns an event with DateTime objects in the right time zone" do
        event = event_repository.available_block(DateTime.now, DateTime.now)
        expect(event.start.date_time).to be_a(DateTime)
        expect(event.end.date_time).to be_a(DateTime)
        expect(event.start.date_time.strftime("%Z")).to eq("-04:00")
        expect(event.end.date_time.strftime("%Z")).to eq("-04:00")
      end
    end

    context "given Time" do
      freeze_time

      it "returns an event with DateTime objects in the right time zone" do
        event = event_repository.available_block(Time.now, Time.now)
        expect(event.start.date_time).to be_a(DateTime)
        expect(event.end.date_time).to be_a(DateTime)
        expect(event.start.date_time.strftime("%Z")).to eq("-04:00")
        expect(event.end.date_time.strftime("%Z")).to eq("-04:00")
      end
    end
  end
end
