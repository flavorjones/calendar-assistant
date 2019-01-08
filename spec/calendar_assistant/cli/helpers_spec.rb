# coding: utf-8
describe CalendarAssistant::CLI::Helpers do
  EventSet = CalendarAssistant::EventSet

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
      freeze_time

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
    it "returns a CalendarAssistant event" do
      expect(subject.now).to be_a(CalendarAssistant::Event)
    end
  end

  describe ".find_av_uri" do
    let(:ca) { instance_double("CalendarAssistant") }
    let(:er) { instance_double("EventRepository") }
    let(:event_set) { EventSet.new er, [] }

    describe "search range" do
      freeze_time

      it "searches in a narrow range around the specified time" do
        range = Time.now..(Time.now+5.minutes)
        expect(ca).to receive(:find_events).with(range).and_return(event_set)

        subject.find_av_uri(ca, "now")
      end
    end

    describe "meeting preference" do
      let(:accepted_event) do
        instance_double "accepted event",
                        av_uri: "accepted",
                        response_status: CalendarAssistant::Event::Response::ACCEPTED
      end

      let(:accepted2_event) do
        instance_double "accepted2 event",
                        av_uri: "accepted2",
                        response_status: CalendarAssistant::Event::Response::ACCEPTED
      end

      let(:tentative_event) do
        instance_double "tentative event",
                        av_uri: "tentative",
                        response_status: CalendarAssistant::Event::Response::TENTATIVE
      end

      let(:needs_action_event) do
        instance_double "needs_action event",
                        av_uri: "needs_action",
                        response_status: CalendarAssistant::Event::Response::NEEDS_ACTION
      end

      let(:declined_event) do
        instance_double "declined event",
                        av_uri: "declined",
                        response_status: CalendarAssistant::Event::Response::DECLINED
      end

      let(:no_av_uri_event) do
        instance_double "no avi uri",
                        av_uri: nil,
                        response_status: CalendarAssistant::Event::Response::ACCEPTED
      end

      it "prefers later meetings to earlier meetings" do
        # reminder that #find_events returns an EventSet with events ordered by start time
        event_set = EventSet.new er, [accepted_event, accepted2_event]
        allow(ca).to receive(:find_events).and_return(event_set)

        actual_set, actual_uri = subject.find_av_uri(ca, "now")
        expect(actual_set.events).to eq(accepted2_event)
        expect(actual_uri).to eq("accepted2")
      end

      it "prefers accepted meetings to all other responses" do
        event_set = EventSet.new er, [accepted_event, tentative_event, needs_action_event, declined_event]
        allow(ca).to receive(:find_events).and_return(event_set)

        actual_set, actual_uri = subject.find_av_uri(ca, "now")
        expect(actual_set.events).to eq(accepted_event)
        expect(actual_uri).to eq("accepted")
      end

      it "prefers tentative meetings to needsAction and declined" do
        event_set = EventSet.new er, [tentative_event, needs_action_event, declined_event]
        allow(ca).to receive(:find_events).and_return(event_set)

        actual_set, actual_uri = subject.find_av_uri(ca, "now")
        expect(actual_set.events).to eq(tentative_event)
        expect(actual_uri).to eq("tentative")
      end

      it "prefers needsAction meetings to declined" do
        event_set = EventSet.new er, [needs_action_event, declined_event]
        allow(ca).to receive(:find_events).and_return(event_set)

        actual_set, actual_uri = subject.find_av_uri(ca, "now")
        expect(actual_set.events).to eq(needs_action_event)
        expect(actual_uri).to eq("needs_action")
      end

      it "never chooses declined meetings" do
        event_set = EventSet.new er, [declined_event]
        allow(ca).to receive(:find_events).and_return(event_set)

        actual_set, actual_uri = subject.find_av_uri(ca, "now")
        expect(actual_set.events).to be_nil
        expect(actual_uri).to be_nil
      end

      it "fails gracefully when the meeting has no link" do
        event_set = EventSet.new er, [no_av_uri_event]
        allow(ca).to receive(:find_events).and_return(event_set)

        actual_set, actual_uri = subject.find_av_uri(ca, "now")
        expect(actual_set.events).to be_nil
        expect(actual_uri).to be_nil
      end
    end
  end
end
