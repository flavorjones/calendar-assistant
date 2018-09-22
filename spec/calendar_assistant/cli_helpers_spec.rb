describe CalendarAssistant::CLIHelpers do
  describe ".parse_datespec" do
    describe "parsing" do
      context "passed a range with two dots" do
        it "parses properly" do
          expect(subject.parse_datespec("today..tomorrow")).to be_a(Range)
        end
      end

      context "passed a range with three dots" do
        it "parses properly" do
          expect(subject.parse_datespec("today...tomorrow")).to be_a(Range)
        end
      end

      context "passed a range with dots and spaces" do
        it "parses properly" do
          expect(subject.parse_datespec("today .. tomorrow")).to be_a(Range)
          expect(subject.parse_datespec("today.. tomorrow")).to be_a(Range)
          expect(subject.parse_datespec("today ..tomorrow")).to be_a(Range)
          expect(subject.parse_datespec("today ... tomorrow")).to be_a(Range)
          expect(subject.parse_datespec("today... tomorrow")).to be_a(Range)
          expect(subject.parse_datespec("today ...tomorrow")).to be_a(Range)
        end
      end
    end

    describe "returned range" do
      around do |example|
        # freeze time so we can mock with Chronic strings
        Timecop.freeze(Time.local(2018, 7, 13, 12, 1, 1)) do
          example.run
        end
      end

      context "passed a single date or time" do
        it "returns a range for all of the date" do
          expect(subject.parse_datespec("today")).to eq(Time.now.beginning_of_day..Time.now.end_of_day)
        end
      end

      context "passed a date range" do
        it "returns a range for all of the days in the date range" do
          expect(subject.parse_datespec("today..tomorrow")).to eq(Time.now.beginning_of_day..(Time.now+1.day).end_of_day)
        end
      end

      context "passed a time range within a single day" do
        it "returns the time range" do
          expect(subject.parse_datespec("five minutes ago .. five minutes from now")).
            to eq(Chronic.parse("five minutes ago")..Chronic.parse("five minutes from now"))
        end
      end
    end
  end

  describe ".now" do
    it { }
  end

  describe CalendarAssistant::CLIHelpers::Out do
    it "test print_now!"
    it "test print_events"
    it "test puts"
    it "test launch"
  end
end
