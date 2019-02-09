describe CalendarAssistant::HasDuration do
  describe "class methods" do
    describe ".duration_in_seconds" do

      context "given DateTimes" do
        it { expect(described_class.duration_in_seconds(Time.now.to_datetime, (Time.now + 1).to_datetime)).to eq(1) }
      end

      context "given Times" do
        it { expect(described_class.duration_in_seconds(Time.now, Time.now + 1)).to eq(1) }
      end
    end
  end
end