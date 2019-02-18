require "date"

describe CalendarAssistant::DateHelpers do
  freeze_time

  let(:attributes) do
    {
      key: "value",
      key_with_a_date_string: "2010-10-10",
      key_with_a_date: Date.today,
      key_with_a_date_time: DateTime.now,
      key_with_a_time: Time.now,
    }
  end

  subject { CalendarAssistant::DateHelpers.cast_dates(attributes) }

  describe "casting dates" do
    it "handles dates" do
      # be explicit to avoid fuzziness introduced by EventDateTime#==
      expect(subject[:key_with_a_date]).to be_a(GCal::EventDateTime)
      expect(subject[:key_with_a_date].date).to eq(attributes[:key_with_a_date].to_s)
    end

    it { is_expected.to include(:key_with_a_date_time => GCal::EventDateTime.new(date_time: DateTime.now)) }
    it { is_expected.to include(:key_with_a_time => GCal::EventDateTime.new(date_time: Time.now)) }
  end

  describe "leaving the others alone" do
    it { is_expected.to include(:key => "value") }

    it "does not attempt to cast strings even if they look like dates" do
      is_expected.to include(:key_with_a_date_string => "2010-10-10")
    end
  end
end
