shared_examples_for "an event repository" do
    let(:calendar_id) { "primary" }
    let(:event_array) { [nine_event, nine_thirty_event] }
    let(:nine_event) { GCal::Event.new(id: 1, start: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 09:00:00")), end: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 10:00:00"))) }
    let(:nine_thirty_event) { GCal::Event.new(id: 2, start: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 09:30:00")), end: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 10:00:00"))) }
    let(:time_range) {Time.parse("2018-10-18")..Time.parse("2018-10-19")}



  describe "#create and #new" do
    context "#create" do
      it "creates an event" do
        event_repository.create({summary: "boom", start: Date.parse("2018-10-17"), end: Date.parse("2018-10-19")})
        expect(event_repository.find(time_range).map(&:summary)).to include("boom")
      end
    end

    context "#new" do
      it "news an event, but does not add it to the repository" do
        event = event_repository.new({summary: "boom", start: Date.parse("2018-10-17"), end: Date.parse("2018-10-19")})
        expect(event_repository.find(time_range).map(&:summary)).not_to include("boom")
        expect(event).to be_a(CalendarAssistant::Event)
      end
    end
  end

  describe "#find" do
    it "sets some basic query options" do
      result = event_repository.find time_range
      expect(result).to eq(event_array)
    end

    context "given a time range" do
      it "calls CalendarService#list_events with the range" do
        result = event_repository.find time_range
        expect(result).to eq(event_array)
      end
    end

    context "when no items are found" do
      let(:time_range) {Time.parse("2017-10-18")..Time.parse("2017-10-19")}

      it "returns an empty array" do
        result = event_repository.find time_range
        expect(result).to eq([])
      end
    end
  end

  describe "#delete" do
    it "calls the service with the event id" do
      event_repository.delete(nine_event)
      result = event_repository.find time_range
      expect(result).not_to include(nine_event)
    end
  end

  describe "#update" do
    let(:time_range) {Time.parse("2018-10-18 08:00")..Time.parse("2018-10-18 09:15")}

    it "casts dates to GCal::EventDateTime and updates the event" do
      new_attributes = { start: DateTime.parse("1776-07-04") }
      event_repository.update(nine_event, new_attributes)

      result = event_repository.find time_range
      expect(result[0].start.date).to eq "1776-07-04T00:00:00+00:00"
    end
  end
end

