describe CalendarAssistant::EventRepositoryFactory do
  describe ".new_event_repository" do
    let(:service) { instance_double "Service" }
    let(:calendar_id) { instance_double "calendar_id" }

    it "creates an EventRepository" do
      expect(CalendarAssistant::EventRepository).to receive(:new).with(service, calendar_id, anything)
      described_class.new_event_repository(service, calendar_id)
    end
  end

  describe ".new_location_event_repository" do
    let(:service) { instance_double "Service" }
    let(:calendar_id) { instance_double "calendar_id" }

    it "creates a LocationEventRepository" do
      expect(CalendarAssistant::LocationEventRepository).to receive(:new).with(service, calendar_id, anything)
      described_class.new_location_event_repository(service, calendar_id)
    end
  end

  describe ".new_lint_event_repository" do
    let(:service) { instance_double "Service" }
    let(:calendar_id) { instance_double "calendar_id" }

    it "creates a LocationEventRepository" do
      expect(CalendarAssistant::LintEventRepository).to receive(:new).with(service, calendar_id, anything)
      described_class.new_lint_event_repository(service, calendar_id)
    end
  end
end
