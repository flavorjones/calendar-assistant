describe CalendarAssistant::EventSet do
  let(:event_repository) { instance_double "EventRepository" }
  let(:events) { [instance_double("Event1"), instance_double("Event2")] }

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
end
