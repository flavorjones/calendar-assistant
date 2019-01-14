describe CalendarAssistant::CLI::EventPresenter do
  let(:decorated_object) { CalendarAssistant::Event.new(Google::Apis::CalendarV3::Event.new(attributes)) }
  subject { described_class.new decorated_object }

  describe "#view_summary" do
    context "event is not private" do
      context "and summary exists" do
        let(:attributes) { { summary: "my summary" } }
        it { expect(subject.view_summary).to eq("my summary") }
      end

      context "and summary is blank" do
        let(:attributes) { { summary: "" } }
        it { expect(subject.view_summary).to eq("(no title)") }
      end

      context "and summary is nil" do
        let(:attributes) { { summary: nil } }
        it { expect(subject.view_summary).to eq("(no title)") }
      end
    end

    context "event is private" do
      context "but we have access" do
        let(:attributes) { { summary: "don't ignore", visibility: CalendarAssistant::Event::Visibility::PRIVATE } }
        it { expect(subject.view_summary).to eq("don't ignore") }
      end

      context "and we do not have access" do
        let(:attributes) { { visibility: CalendarAssistant::Event::Visibility::PRIVATE } }
        it { expect(subject.view_summary).to eq("(private)") }
      end
    end
  end
end
