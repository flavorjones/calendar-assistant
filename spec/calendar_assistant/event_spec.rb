require 'date'

describe CalendarAssistant::Event do
  let(:decorated_class) { Google::Apis::CalendarV3::Event }

  describe "#location_event?" do
    context "event summary does not begin with a worldmap emoji" do
      let(:decorated_object) { decorated_class.new(summary: "not a location event") }

      it "returns false" do
        expect(described_class.new(decorated_object).location_event?).to be_falsey
      end
    end

    context "event summary begins with a worldmap emoji" do
      let(:decorated_object) { decorated_class.new(summary: "🗺 yes a location event") }

      it "returns true" do
        expect(described_class.new(decorated_object).location_event?).to be_truthy
      end
    end
  end
end
