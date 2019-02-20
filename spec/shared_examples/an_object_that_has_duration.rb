require "date"

shared_examples_for "an object that has duration" do
  subject { an_object }

  freeze_time

  describe "instance methods" do
    let(:params) { { start: start_param, end: end_param } }
    let(:start_param) { nil }
    let(:end_param) { nil }

    describe "#all_day?" do
      context "object has start and end dates" do
        let(:start_param) { GCal::EventDateTime.new(date: Date.today) }
        let(:end_param) { GCal::EventDateTime.new(date: Date.today + 1) }

        it { is_expected.to be_all_day }
      end

      context "object has just a start date" do
        let(:start_param) { GCal::EventDateTime.new(date: Date.today) }

        it { is_expected.to be_all_day }
      end

      context "object has just an end date" do
        let(:end_param) { GCal::EventDateTime.new(date: Date.today + 1) }

        it { is_expected.to be_all_day }
      end

      context "object has start and end times" do
        let(:start_param) { GCal::EventDateTime.new(date_time: Time.now) }
        let(:end_param) { GCal::EventDateTime.new(date_time: Time.now + 30.minutes) }

        it { is_expected.not_to be_all_day }
      end
    end

    describe "#future?" do
      let(:end_param) { GCal::EventDateTime.new(date: Date.today + 7) }

      context "all day object" do
        context "when the object starts in the past" do
          let(:start_param) { GCal::EventDateTime.new(date: Date.today - 1) }

          it { is_expected.not_to be_future }
        end

        context "when the object starts today" do
          let(:start_param) { GCal::EventDateTime.new(date: Date.today) }

          it { is_expected.not_to be_future }
        end

        context "when the object starts in the future" do
          let(:start_param) { GCal::EventDateTime.new(date: Date.today + 1) }

          it { is_expected.to be_future }
        end
      end

      context "intraday object" do
        let(:end_param) { GCal::EventDateTime.new(date_time: Time.now + 30.minutes) }

        context "when the object starts in the past" do
          let(:start_param) { GCal::EventDateTime.new(date_time: Time.now - 1) }

          it { is_expected.not_to be_future }
        end

        context "when the object starts in the past" do
          let(:start_param) { GCal::EventDateTime.new(date_time: Time.now) }
          it { is_expected.not_to be_future }
        end

        context "when the object starts in the past" do
          let(:start_param) { GCal::EventDateTime.new(date_time: Time.now + 1) }

          it { is_expected.to be_future }
        end
      end
    end

    describe "#past?" do
      context "all day object" do
        let(:start_param) { GCal::EventDateTime.new(date: Date.today - 7) }

        context "when the object ends in the past" do
          let(:end_param) { GCal::EventDateTime.new(date: Date.today - 1) }

          it { is_expected.to be_past }
        end

        context "when the object ends today" do
          let(:end_param) { GCal::EventDateTime.new(date: Date.today) }

          it { is_expected.to be_past }
        end

        context "when the object ends in the future" do
          let(:end_param) { GCal::EventDateTime.new(date: Date.today + 1) }

          it { is_expected.not_to be_past }
        end
      end

      context "intraday object" do
        let(:start_param) { GCal::EventDateTime.new(date_time: Time.now - 30.minutes) }

        context "when the object ends in the past" do
          let(:end_param) { GCal::EventDateTime.new(date_time: Time.now - 1) }

          it { is_expected.to be_past }
        end

        context "when the object ends today" do
          let(:end_param) { GCal::EventDateTime.new(date_time: Time.now) }

          it { is_expected.to be_past }
        end

        context "when the object ends in the future" do
          let(:end_param) { GCal::EventDateTime.new(date_time: Time.now + 1) }

          it { is_expected.not_to be_past }
        end
      end
    end

    describe "#current?" do
      let(:start_param) { GCal::EventDateTime.new(date: Date.today - 7) }

      context "when the object ends in the past" do
        let(:end_param) { GCal::EventDateTime.new(date: Date.today - 1) }

        it { is_expected.not_to be_current }
      end

      context "when the object is happening now" do
        let(:end_param) { GCal::EventDateTime.new(date: Date.today + 1) }

        it { is_expected.to be_current }
      end

      context "when the object starts in the future" do
        let(:start_param) { GCal::EventDateTime.new(date: Date.today + 1) }
        let(:end_param) { GCal::EventDateTime.new(date: Date.today + 2) }

        it { is_expected.not_to be_current }
      end
    end

    describe "compare methods" do
      let(:rhs_class) { Struct.new(:start, :end).include(CalendarAssistant::HasDuration) }

      let(:rhs) { rhs_class.new(rhs_start_date, rhs_end_date) }

      describe "cover?" do
        let(:rhs_start_date) { GCal::EventDateTime.new(date: Date.today) }
        let(:rhs_end_date) { GCal::EventDateTime.new(date: Date.today + 1) }
        let(:start_param) { rhs_start_date }
        let(:end_param) { GCal::EventDateTime.new(date: Date.today + 1) }

        context "when other object occurs within the range of this object" do
          it "returns true" do
            expect(subject.cover?(rhs)).to be_truthy
          end
        end

        context "when the other object does not occur within the range of this object" do
          let(:rhs_end_date) { GCal::EventDateTime.new(date: Date.today + 10) }

          it "returns false" do
            expect(subject.cover?(rhs)).to be_falsey
          end
        end
      end

      describe "overlaps_end_of?" do
        let(:rhs_start_date) { GCal::EventDateTime.new(date: Date.today + 2) }
        let(:rhs_end_date) { GCal::EventDateTime.new(date: Date.today + 6) }
        let(:start_param) { GCal::EventDateTime.new(date: Date.today + 1) }
        let(:end_param) { GCal::EventDateTime.new(date: Date.today + 5) }

        context "when other object overlaps end of this object" do
          it "returns true" do
            expect(subject.overlaps_start_of?(rhs)).to be_truthy
          end
        end

        context "when the other object does not overlap end date of this object" do
          let(:rhs_end_date) { GCal::EventDateTime.new(date: Date.today) }

          it "returns false" do
            expect(subject.overlaps_start_of?(rhs)).to be_falsey
          end
        end
      end

      describe "overlaps_start_of?" do
        let(:rhs_start_date) { GCal::EventDateTime.new(date: Date.today) }
        let(:rhs_end_date) { GCal::EventDateTime.new(date: Date.today + 5) }
        let(:start_param) { GCal::EventDateTime.new(date: Date.today + 2) }
        let(:end_param) { GCal::EventDateTime.new(date: Date.today + 5) }

        context "when other object overlaps start of this object" do
          it "returns true" do
            expect(subject.overlaps_end_of?(rhs)).to be_truthy
          end
        end

        context "when the other object does not overlap start date of this object" do
          let(:rhs_start_date) { GCal::EventDateTime.new(date: Date.today + 4) }

          it "returns false" do
            expect(subject.overlaps_end_of?(rhs)).to be_falsey
          end
        end
      end
    end

    describe "#start_time" do
      context "all day object" do
        context "containing a Date class" do
          let(:start_param) { GCal::EventDateTime.new(date: Date.today) }

          it { expect(subject.start_time).to eq(Date.today.beginning_of_day) }
        end

        context "containing a String class" do
          let(:start_param) { GCal::EventDateTime.new(date: Date.today.to_s) }

          it { expect(subject.start_time).to eq(Date.today.beginning_of_day) }
        end
      end

      context "intraday object" do
        context "containing a Time class" do
          let(:start_param) { GCal::EventDateTime.new(date_time: Time.now) }

          it { expect(subject.start_time).to eq(Time.now) }
        end

        context "containing a DateTime class" do
          let(:start_param) { GCal::EventDateTime.new(date_time: DateTime.now) }

          it { expect(subject.start_time).to eq(DateTime.now) }
        end
      end
    end

    describe "#start_date" do
      context "all day object" do
        # test Date and String
        context "containing a Date class" do
          let(:start_param) { GCal::EventDateTime.new(date: Date.today) }

          it { expect(subject.start_date).to eq(Date.today) }
        end

        context "containing a String class" do
          let(:start_param) { GCal::EventDateTime.new(date: Date.today.to_s) }

          it { expect(subject.start_date).to eq(Date.today) }
        end
      end

      context "intraday object" do
        context "containing a Time class" do
          let(:start_param) { GCal::EventDateTime.new(date_time: Time.now) }

          it { expect(subject.start_date).to eq(Date.today) }
        end

        context "containing a DateTime class" do
          let(:start_param) { GCal::EventDateTime.new(date_time: DateTime.now) }

          it { expect(subject.start_date).to eq(Date.today) }
        end
      end
    end

    describe "#end_time" do
      context "all day object" do
        context "containing a Date class" do
          let(:end_param) { GCal::EventDateTime.new(date: Date.today) }

          it { expect(subject.end_time).to eq(Date.today.beginning_of_day) }
        end

        context "containing a String class" do
          let(:end_param) { GCal::EventDateTime.new(date: Date.today.to_s) }

          it { expect(subject.end_time).to eq(Date.today.beginning_of_day) }
        end
      end

      context "intraday object" do
        context "containing a Time class" do
          let(:end_param) { GCal::EventDateTime.new(date_time: Time.now) }

          it { expect(subject.end_time).to eq(Time.now) }
        end

        context "containing a DateTime class" do
          let(:end_param) { GCal::EventDateTime.new(date_time: DateTime.now) }

          it { expect(subject.end_time).to eq(DateTime.now) }
        end
      end
    end

    describe "#end_date" do
      context "all day object" do
        context "containing a Date class" do
          let(:end_param) { GCal::EventDateTime.new(date: Date.today) }

          it { expect(subject.end_date).to eq(Date.today) }
        end

        context "containing a String class" do
          let(:end_param) { GCal::EventDateTime.new(date: Date.today.to_s) }

          it { expect(subject.end_date).to eq(Date.today) }
        end
      end
    end

    context "intraday object" do
      context "containing a Time class" do
        let(:end_param) { GCal::EventDateTime.new(date_time: Time.now) }

        it { expect(subject.end_date).to eq(Date.today) }
      end

      context "containing a DateTime class" do
        let(:end_param) { GCal::EventDateTime.new(date_time: DateTime.now) }

        it { expect(subject.end_date).to eq(Date.today) }
      end
    end

    describe "#duration" do
      context "for a one-day all-day object" do
        let(:start_param) { GCal::EventDateTime.new(date: Date.today) }
        let(:end_param) { GCal::EventDateTime.new(date: Date.today + 1) }

        it { expect(subject.duration).to eq("1d") }
      end

      context "for an multi-day all-day object" do
        let(:start_param) { GCal::EventDateTime.new(date: Date.today) }
        let(:end_param) { GCal::EventDateTime.new(date: Date.today + 3) }

        it { expect(subject.duration).to eq("3d") }
      end

      context "for an intraday object" do
        let(:start_param) { GCal::EventDateTime.new(date_time: Time.now) }
        let(:end_param) { GCal::EventDateTime.new(date_time: Time.now + 150.minutes) }

        it { expect(subject.duration).to eq("2h 30m") }
      end
    end

    describe "#duration_in_seconds" do
      let(:duration) { instance_double("duration") }

      let(:start_param) { GCal::EventDateTime.new(date_time: Time.now) }
      let(:end_param) { GCal::EventDateTime.new(date_time: Time.now + 150.minutes) }

      it "calls Event.duration_in_seconds with the start and end times" do
        expect(CalendarAssistant::HasDuration).to receive(:duration_in_seconds).
                                                    with(start_param.date_time, end_param.date_time).
                                                    and_return(duration)

        result = subject.duration_in_seconds
        expect(result).to eq(duration)
      end
    end

    describe "#contains?" do
      freeze_time
      let(:time_zone) { ENV["TZ"] }

      subject { in_tz { an_object } }

      context "all-day object" do
        let(:start_param) { GCal::EventDateTime.new(date: Date.today) }
        let(:end_param) { GCal::EventDateTime.new(date: Date.today + 1) }

        context "time in same time zone" do
          it { expect(subject.contains?(Chronic.parse("#{(Date.today - 1).to_s} 11:59pm"))).to be_falsey }
          it { expect(subject.contains?(Chronic.parse("#{Date.today.to_s} 12am"))).to be_truthy }
          it { expect(subject.contains?(Chronic.parse("#{Date.today.to_s} 10am"))).to be_truthy }
          it { expect(subject.contains?(Chronic.parse("#{Date.today.to_s} 11:59pm"))).to be_truthy }
          it { expect(subject.contains?(Chronic.parse("#{(Date.today + 1).to_s} 12am"))).to be_falsey }
        end

        context "time in a different time zone" do
          let(:time_zone) { "America/Los_Angeles" }

          it do
            date = in_tz("America/New_York") { Chronic.parse("#{Date.today} 2:59am") }
            in_tz { expect(subject.contains?(date)).to be_falsey }
          end

          it do
            date = in_tz("America/New_York") { Chronic.parse("#{Date.today} 3am") }
            in_tz { expect(subject.contains?(date)).to be_truthy }
          end
        end
      end

      context "intraday object" do
        let(:start_param) { GCal::EventDateTime.new(date_time: Chronic.parse("9am")) }
        let(:end_param) { GCal::EventDateTime.new(date_time: Chronic.parse("9pm")) }

        context "time in same time zone" do
          it { expect(subject.contains?(Chronic.parse("8:59am"))).to be_falsey }
          it { expect(subject.contains?(Chronic.parse("9am"))).to be_truthy }
          it { expect(subject.contains?(Chronic.parse("10am"))).to be_truthy }
          it { expect(subject.contains?(Chronic.parse("8:59pm"))).to be_truthy }
          it { expect(subject.contains?(Chronic.parse("9pm"))).to be_falsey }
        end

        context "time in a different time zone" do
          let(:time_zone) { "America/Los_Angeles" }

          it do
            date = in_tz("America/New_York") { Chronic.parse("11:59am") }
            expect(subject.contains?(date)).to be_falsey
          end

          it do
            date = in_tz("America/New_York") { Chronic.parse("12pm") }
            expect(subject.contains?(date)).to be_truthy
          end

          it do
            date = in_tz("America/New_York") { Chronic.parse("11:59pm") }
            expect(subject.contains?(date)).to be_truthy
          end

          it do
            date = in_tz("America/New_York") { Chronic.parse("#{Date.today + 1} 12am") }
            expect(subject.contains?(date)).to be_falsey
          end
        end
      end
    end
  end
end
