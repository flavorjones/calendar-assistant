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

    describe ".cast_datetime" do
      context "given DateTime" do
        freeze_time

        it "returns an event with DateTime objects in the right time zone" do
          event = described_class.cast_datetime(DateTime.now, "America/New_York")
          expect(event.date_time).to be_a(DateTime)
          expect(event.date_time.strftime("%Z")).to eq("-04:00")
        end
      end

      context "given Time" do
        freeze_time

        it "returns an event with DateTime objects in the right time zone" do
          event = described_class.cast_datetime(Time.now, "America/New_York")
          expect(event.date_time).to be_a(DateTime)
          expect(event.date_time.strftime("%Z")).to eq("-04:00")
        end
      end
    end
  end
end