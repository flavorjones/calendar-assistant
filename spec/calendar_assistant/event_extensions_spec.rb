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

  describe "#all_day?" do
    context "event has start and end dates" do
      subject do
        described_class.new start: GCal::EventDateTime.new(date: Date.today),
                            end: GCal::EventDateTime.new(date: Date.today + 1)
      end

      it { expect(subject.all_day?).to be_truthy }
    end

    context "event has start and end times" do
      subject do
        described_class.new start: GCal::EventDateTime.new(date_time: Time.now),
                            end: GCal::EventDateTime.new(date_time: Time.now + 30.minutes)
      end

      it { expect(subject.all_day?).to be_falsey }
    end
  end

  describe "#past?" do
    freeze_time

    context "all day event" do
      subject { described_class.new start: GCal::EventDateTime.new(date: Date.today-7) }

      it "returns true if the event ends today or later" do
        expect(subject.update(end: GCal::EventDateTime.new(date: Date.today-1)).past?).to be_truthy
        expect(subject.update(end: GCal::EventDateTime.new(date: Date.today)).past?).to be_truthy
        expect(subject.update(end: GCal::EventDateTime.new(date: Date.today+1)).past?).to be_falsey
      end
    end

    context "intraday event" do
      subject { described_class.new start: GCal::EventDateTime.new(date_time: Time.now - 30.minutes) }

      it "returns true if the event ends now or later" do
        expect(subject.update(end: GCal::EventDateTime.new(date_time: Time.now - 1.minute)).past?).to be_truthy
        expect(subject.update(end: GCal::EventDateTime.new(date_time: Time.now)).past?).to be_truthy
        expect(subject.update(end: GCal::EventDateTime.new(date_time: Time.now + 1.minute)).past?).to be_falsey
      end
    end
  end

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
        described_class.new description: "zoom at https://company.zoom.us/j/123412341 please",
                            hangout_link: nil
      end

      it "returns the URI" do
        expect(event.av_uri).to eq("https://company.zoom.us/j/123412341")
      end
    end

    context "has a hangout link" do
      let(:event) do
        described_class.new description: "see you in the hangout",
                            hangout_link: "https://plus.google.com/hangouts/_/company.com/yerp?param=random"
      end

      it "returns the URI" do
        expect(event.av_uri).to eq("https://plus.google.com/hangouts/_/company.com/yerp?param=random")
      end
    end

    context "has no known av links" do
      let(:event) do
        described_class.new description: "we'll meet in person",
                            hangout_link: nil
      end

      it "returns nil" do
        expect(event.av_uri).to be_nil
      end
    end
  end
end

describe Google::Apis::CalendarV3::EventDateTime do
  describe "#to_date" do
    context "all day event" do
      context "storing a Date" do
        it { expect(described_class.new(date: Date.today).to_date).to be_a(Date) }
      end

      context "storing a string" do
        it { expect(described_class.new(date: "2018-09-01").to_date).to be_a(Date) }
      end
    end

    context "intraday event" do
      it { expect(described_class.new(date_time: Time.now).to_date).to be_nil }
    end
  end

  describe "#to_s" do it end
end
