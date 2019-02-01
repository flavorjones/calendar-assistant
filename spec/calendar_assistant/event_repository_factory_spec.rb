describe CalendarAssistant::EventRepositoryFactory do
  describe ".new_event_repository" do
    let(:service) { instance_double "Service" }
    let(:calendar_id) { instance_double "calendar_id" }

    context "when no type is set" do
      it "creates an EventRepository" do
        expect(CalendarAssistant::EventRepository).to receive(:new).with(service, calendar_id, anything)
        described_class.new_event_repository(service, calendar_id)
      end
    end

    context "when a type is set that is nil or weird" do
      it "creates an EventRepository" do
        expect(CalendarAssistant::EventRepository).to receive(:new).with(service, calendar_id, anything).twice
        described_class.new_event_repository(service, calendar_id, type: :something_strange)
        described_class.new_event_repository(service, calendar_id, type: nil)
      end
    end

    context "when the type is lint" do
      it "creates a LintEventRepository" do
        expect(CalendarAssistant::LintEventRepository).to receive(:new).with(service, calendar_id, anything)
        described_class.new_event_repository(service, calendar_id, type: :lint)
      end
    end

    context "when the type is location" do
      it "creates a LocationEventRepository" do
        expect(CalendarAssistant::LocationEventRepository).to receive(:new).with(service, calendar_id, anything)
        described_class.new_event_repository(service, calendar_id, type: :location)
      end
    end
  end
end
