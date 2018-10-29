require 'date'

describe CalendarAssistant::EventRepository do

  let(:service) {instance_double("CalendarService")}
  let(:calendar_id) { "primary" }
  let(:event_repository) {described_class.new(service, "primary")}
  let(:event_array) {[instance_double("Event"), instance_double("Event")]}
  let(:events) {instance_double("Events", :items => event_array)}

  describe "#find" do
    let(:time_range) {Time.now..(Time.now + 1.day)}

    it "sets some basic query options" do
      expect(service).to receive(:list_events).with("primary",
                                                    hash_including(order_by: "startTime",
                                                                   single_events: true,
                                                                   max_results: anything)).
          and_return(events)
      result = event_repository.find time_range
      expect(result).to eq(event_array)
    end

    context "given a time range" do
      it "calls CalendarService#list_events with the range" do
        expect(service).to receive(:list_events).with("primary",
                                                      hash_including(time_min: time_range.first.iso8601,
                                                                     time_max: time_range.last.iso8601)).
            and_return(events)
        result = event_repository.find time_range
        expect(result).to eq(event_array)
      end
    end

    context "when no items are found" do
      let(:events) {instance_double("Events", :items => nil)}

      it "returns an empty array" do
        expect(service).to receive(:list_events).and_return(events)
        result = event_repository.find time_range
        expect(result).to eq([])
      end
    end
  end

  describe "#delete" do
    it "calls the service with the event id" do
      event = double(:event, id: 1)

      expect(service).to receive(:delete_event).with(calendar_id, event.id)
      event_repository.delete(event)
    end
  end

  describe "#update" do
    context "no date values" do
      it "updates the event and the service" do
        event = double(:event, id: 1)
        new_attributes = {funky: "cold medina"}
        expect(event).to receive(:update!).with(new_attributes)
        expect(service).to receive(:update_event).with(calendar_id, event.id, event)
        event_repository.update(event, new_attributes)
      end
    end

    context "with date values" do
      it "casts dates to GCal::EventDateTime" do
        event = double(:event, id: 1)
        new_attributes = {random_date: Date.today}
        allow(service).to receive(:update_event)

        expect(event).to receive(:update!) do |attributes|
          date_attr = attributes[:random_date];
          expect(date_attr.date).to eq(Date.today.iso8601)
          expect(date_attr).to be_kind_of(GCal::EventDateTime)
        end


        event_repository.update(event, new_attributes)
      end
    end
  end
end
