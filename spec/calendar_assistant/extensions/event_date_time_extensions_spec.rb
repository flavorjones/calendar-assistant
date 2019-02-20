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

  describe "#to_date!" do
    context "all day event" do
      context "storing a Date" do
        it { expect(described_class.new(date: Date.today).to_date!).to be_a(Date) }
      end

      context "storing a string" do
        it { expect(described_class.new(date: "2018-09-01").to_date!).to be_a(Date) }
      end
    end

    context "intraday event" do
      it { expect(described_class.new(date_time: Time.now).to_date!).to be_a(Date) }
    end
  end

  describe "#to_s" do
    context "date" do
      context "storing a Date" do
        subject { described_class.new date: Date.parse("2019-09-01") }
        it { expect(subject.to_s).to eq("2019-09-01") }
      end

      context "storing a string" do
        subject { described_class.new date: "2019-09-01" }
        it { expect(subject.to_s).to eq("2019-09-01") }
      end
    end

    context "time" do
      let(:time) { Time.parse "2019-09-01 13:14:15" }

      subject { described_class.new date_time: time }
      it { expect(subject.to_s).to eq("2019-09-01 13:14") }
    end
  end

  describe "#==" do
    context "comparing a date to a datetime" do
      it { expect(described_class.new(date: Date.parse("2018-01-01")) == described_class.new(date_time: Time.now)).to be_falsey }

      it { expect(described_class.new(date_time: Time.now) == described_class.new(date: Date.parse("2018-01-01"))).to be_falsey }
    end

    context "comparing dates" do
      it { expect(described_class.new(date: Date.parse("2018-01-01")) == described_class.new(date: Date.parse("2018-01-01"))).to be_truthy }
      it { expect(described_class.new(date: "2018-01-01") == described_class.new(date: Date.parse("2018-01-01"))).to be_truthy }
      it { expect(described_class.new(date: Date.parse("2018-01-01")) == described_class.new(date: "2018-01-01")).to be_truthy }

      it { expect(described_class.new(date: Date.parse("2018-01-02")) == described_class.new(date: Date.parse("2018-01-01"))).to be_falsey }
      it { expect(described_class.new(date: "2018-01-02") == described_class.new(date: Date.parse("2018-01-01"))).to be_falsey }
      it { expect(described_class.new(date: Date.parse("2018-01-02")) == described_class.new(date: "2018-01-01")).to be_falsey }
    end

    context "comparing datetimes" do
      freeze_time

      it { expect(described_class.new(date_time: Time.now.to_datetime) == described_class.new(date_time: Time.now.to_datetime)).to be_truthy }
      it { expect(described_class.new(date_time: Time.now.to_datetime) == described_class.new(date_time: (Time.now + 1).to_datetime)).to be_falsey }
    end

    context "comparing time to datetime" do
      freeze_time

      it { expect(described_class.new(date_time: Time.now) == described_class.new(date_time: Time.now.to_datetime)).to be_truthy }
      it { expect(described_class.new(date_time: Time.now.to_datetime) == described_class.new(date_time: (Time.now + 1))).to be_falsey }
      it { expect(described_class.new(date_time: Time.now.to_datetime) == described_class.new(date_time: Time.now)).to be_truthy }
      it { expect(described_class.new(date_time: Time.now) == described_class.new(date_time: (Time.now + 1).to_datetime)).to be_falsey }
    end
  end
end
