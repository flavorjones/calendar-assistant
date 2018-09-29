# coding: utf-8
describe Google::Apis::CalendarV3::Event do
  describe "#location_event?" do
    context "event summary does not begin with a worldmap emoji" do
      it "returns false" do
        expect(described_class.new(summary: "not a location event").location_event?).to be_falsey
      end
    end

    context "event summary begins with a worldmap emoji" do
      it "returns true" do
        expect(described_class.new(summary: "🗺 yes a location event").location_event?).to be_truthy
      end
    end
  end

  describe "#all_day?" do it end
  describe "#past?" do it end
  describe "#current?" do it end
  describe "#future?" do it end
  describe "#start_date" do it end
  describe "#attendee" do it end
  describe "#recurrence_rules?" do it end
  describe "#recurrence" do it end
  describe "#recurrence_parent" do it end
  describe "#response_status" do it end
  describe "#declined?" do it end

  describe "av_uri" do
    context "description has a zoom link" do
      let(:event) do
        GCal::Event.new description: "zoom at https://company.zoom.us/j/123412341 please",
                        hangout_link: nil
      end

      it "returns the URI" do
        expect(event.av_uri).to eq("https://company.zoom.us/j/123412341")
      end
    end

    context "has a hangout link" do
      let(:event) do
        GCal::Event.new description: "see you in the hangout",
                        hangout_link: "https://plus.google.com/hangouts/_/company.com/yerp?param=random"
      end

      it "returns the URI" do
        expect(event.av_uri).to eq("https://plus.google.com/hangouts/_/company.com/yerp?param=random")
      end
    end

    context "has no known av links" do
      let(:event) do
        GCal::Event.new description: "we'll meet in person",
                        hangout_link: nil
      end

      it "returns nil" do
        expect(event.av_uri).to be_nil
      end
    end
  end
end

describe Google::Apis::CalendarV3::EventDateTime do
  describe "#ensure_date" do it end
  describe "#to_s" do it end
end
