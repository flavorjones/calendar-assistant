# coding: utf-8
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

    describe "search range" do
      freeze_time

      it "searches in a narrow range around the specified time" do
        range = Time.now..(Time.now+5.minutes)
        expect(ca).to receive(:find_events).with(range).and_return([])

        subject.find_av_uri(ca, "now")
      end
    end

    describe "meeting preference" do
      let(:accepted_event) do
        instance_double "accepted event",
                        av_uri: "accepted",
                        response_status: GCal::Event::Response::ACCEPTED
      end

      let(:accepted2_event) do
        instance_double "accepted2 event",
                        av_uri: "accepted2",
                        response_status: GCal::Event::Response::ACCEPTED
      end

      let(:tentative_event) do
        instance_double "tentative event",
                        av_uri: "tentative",
                        response_status: GCal::Event::Response::TENTATIVE
      end

      let(:needs_action_event) do
        instance_double "needs_action event",
                        av_uri: "needs_action",
                        response_status: GCal::Event::Response::NEEDS_ACTION
      end

      let(:declined_event) do
        instance_double "declined event",
                        av_uri: "declined",
                        response_status: GCal::Event::Response::DECLINED
      end

      it "prefers later meetings to earlier meetings" do
        # reminder that #find_events returns in order of start time
        allow(ca).to receive(:find_events).and_return([accepted_event, accepted2_event])

        expect(subject.find_av_uri(ca, "now")).to eq([accepted2_event, "accepted2"])
      end

      it "prefers accepted meetings to all other responses" do
        allow(ca).to receive(:find_events).and_return([accepted_event, tentative_event, needs_action_event, declined_event])

        expect(subject.find_av_uri(ca, "now")).to eq([accepted_event, "accepted"])
      end

      it "prefers tentative meetings to needsAction and declined" do
        allow(ca).to receive(:find_events).and_return([tentative_event, needs_action_event, declined_event])

        expect(subject.find_av_uri(ca, "now")).to eq([tentative_event, "tentative"])
      end

      it "prefers needsAction meetings to declined" do
        allow(ca).to receive(:find_events).and_return([needs_action_event, declined_event])

        expect(subject.find_av_uri(ca, "now")).to eq([needs_action_event, "needs_action"])
      end

      it "never chooses declined meetings" do
        allow(ca).to receive(:find_events).and_return([declined_event])

        expect(subject.find_av_uri(ca, "now")).to eq(nil)
      end
    end
  end

  describe CalendarAssistant::CLIHelpers::Out do
    let(:stdout) { StringIO.new }
    let(:ca) { instance_double("CalendarAssistant") }
    subject { described_class.new(stdout) }

    describe "#launch" do
      let(:url) { "https://this.is.a.url.com/foo/bar#asdf?q=123" }

      it "calls Launchy.open with the url" do
        expect(Launchy).to receive(:open).with(url)
        subject.launch(url)
      end
    end

    describe "#puts" do
      let(:args) { [1, 2, 3, "a", "b", {"c" => "d"}] }

      it "calls #puts on the IO object with the args" do
        expect(stdout).to receive(:puts).with(*args)
        subject.puts(*args)
      end
    end

    describe "#print_now!" do
      freeze_time

      let(:event) { CalendarAssistant::Event.new(GCal::Event.new start: GCal::EventDateTime.new(date_time: start_time)) }
      let(:now) { instance_double("Event<now>") }

      before do
        allow(CalendarAssistant::CLIHelpers).to receive(:now).and_return(now)
      end

      context "having not printed yet" do
        let(:printed) { false }

        context "event start time is earlier than now" do
          let(:start_time) { Time.now - 1.minute }

          it "does not print and returns false" do
            expect(ca).not_to receive(:event_description)
            rval = subject.print_now!(ca, event, printed)
            expect(rval).to be_falsey
          end
        end

        context "event start time is later than now but on a different day" do
          let(:start_time) { Time.now + 1.day + 1.minute }

          it "does not print and returns false" do
            expect(ca).not_to receive(:event_description)
            rval = subject.print_now!(ca, event, printed)
            expect(rval).to be_falsey
          end
        end

        context "event start time is later than now" do
          let(:start_time) { Time.now + 1.minute }

          it "prints and returns true" do
            expect(ca).to receive(:event_description).with(now)
            rval = subject.print_now!(ca, event, printed)
            expect(rval).to be_truthy
          end
        end
      end

      context "having already printed" do
        let(:printed) { true }

        context "event start time is later than now" do
          let(:start_time) { Time.now + 1.minute }

          it "does not print and returns true" do
            expect(ca).not_to receive(:event_description).with(now)
            rval = subject.print_now!(ca, event, printed)
            expect(rval).to be_truthy
          end
        end
      end
    end

    describe "#print_events" do
      let(:calendar) { instance_double("Calendar") }
      let(:calendar_id) { "calendar-id" }
      let(:title_regexp) { Regexp.new("#{calendar_id}.*#{calendar_time_zone}") }
      let(:calendar_time_zone) { "calendar/time/zone" }
      let(:events) do
        [
          CalendarAssistant::Event.new(GCal::Event.new(summary: "do a thing",
                          start: GCal::EventDateTime.new(date_time: Time.now))),
          CalendarAssistant::Event.new(GCal::Event.new(summary: "do another thing",
                          start: GCal::EventDateTime.new(date_time: Time.now))),
        ]
      end
      let(:event) { events.first }

      before do
        allow(ca).to receive(:calendar).and_return(calendar)
        allow(calendar).to receive(:id).and_return(calendar_id)
        allow(calendar).to receive(:time_zone).and_return(calendar_time_zone)
        allow(ca).to receive(:event_description)
        allow(stdout).to receive(:puts)
      end

      context "passed a single Event" do
        it "prints a title containing the cal id and time zone" do
          expect(stdout).to receive(:puts).with(title_regexp)
          subject.print_events ca, event
        end

        context "passed option omit_title:true" do
          it "does not print a title" do
            expect(stdout).not_to receive(:puts).with(title_regexp)
            subject.print_events ca, event, omit_title: true
          end
        end

        it "prints the event description" do
          expect(ca).to receive(:event_description).with(event).and_return("event-description")
          expect(stdout).to receive(:puts).with("event-description")
          subject.print_events ca, event
        end
      end

      context "passed an Array of Events" do
        it "prints a title containing the cal id and time zone" do
          expect(stdout).to receive(:puts).with(title_regexp)
          subject.print_events ca, events
        end

        it "calls #print_now! before each event" do
          expect(subject).to receive(:print_now!).exactly(events.length).times
          subject.print_events ca, events
        end

        it "calls puts with event descriptions for each Event" do
          events.each do |event|
            expect(ca).to receive(:event_description).with(event).and_return(event.summary)
            expect(stdout).to receive(:puts).with(event.summary)
          end
          subject.print_events ca, events
        end

        context "option 'commitments'" do
          it "omits events that are not a commitment" do
            allow(events.first).to receive(:commitment?).and_return(true)
            allow(events.last).to receive(:commitment?).and_return(false)

            expect(ca).to receive(:event_description).with(events.first)
            expect(ca).not_to receive(:event_description).with(events.last)

            subject.print_events ca, events, commitments: true
          end
        end

        context "the array is empty" do
          it "prints a standard message" do
            expect(stdout).to receive(:puts).with("No events in this time range.")
            subject.print_events ca, []
          end
        end

        context "the array is nil" do
          it "prints a standard message" do
            expect(stdout).to receive(:puts).with("No events in this time range.")
            subject.print_events ca, nil
          end
        end
      end

      context "passed a Hash of Arrays of Events" do
        it "prints a title containing the cal id and time zone" do
          expect(stdout).to receive(:puts).with(title_regexp)
          subject.print_events ca, {}
        end

        it "prints each hash key capitalized" do
          expect(stdout).to receive(:puts).with(/First:/)
          expect(stdout).to receive(:puts).with(/Second:/)
          subject.print_events ca, {first: [events.first], second: [events.second]}
        end

        it "recursively calls #print_events for each hash value" do
          allow(subject).to receive(:print_events).and_call_original
          expect(subject).to receive(:print_events).with(ca, [events.first], omit_title: true)
          expect(subject).to receive(:print_events).with(ca, [events.second], omit_title: true)
          subject.print_events ca, {first: [events.first], second: [events.second]}
        end
      end
    end

    describe "#print_available_blocks" do
      let(:calendar) { instance_double("Calendar") }
      let(:calendar_id) { "calendar-id" }
      let(:title_regexp) { Regexp.new("#{calendar_id}.*#{calendar_time_zone}", Regexp::MULTILINE) }
      let(:calendar_time_zone) { "calendar/time/zone" }
      let(:config) { CalendarAssistant::Config.new }

      before do
        allow(ca).to receive(:calendar).and_return(calendar)
        allow(calendar).to receive(:id).and_return(calendar_id)
        allow(calendar).to receive(:time_zone).and_return(calendar_time_zone)
        allow(ca).to receive(:event_description)
        allow(ca).to receive(:config).and_return(config)
        allow(stdout).to receive(:puts)
      end

      context "passed an Array of Events" do
        let(:events) do
          [
            CalendarAssistant::Event.new(GCal::Event.new(summary: "do a thing",
                            start: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 09:00:00")),
                            end: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 10:00:00")))),
            CalendarAssistant::Event.new(GCal::Event.new(summary: "do another thing",
                            start: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 12:30:00")),
                            end: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 14:00:00")))),
          ]
        end

        it "prints a title containing the time zone" do
          expect(stdout).to receive(:puts).with(title_regexp)
          subject.print_available_blocks ca, events
        end

        context "passed option omit_title:true" do
          it "does not print a title" do
            expect(stdout).not_to receive(:puts).with(title_regexp)
            subject.print_available_blocks ca, events, omit_title: true
          end
        end

        it "prints out the time range of each free block" do
          expect(stdout).to receive(:puts).with(" • 9:00am - 10:00am")
          expect(stdout).to receive(:puts).with(" • 12:30pm - 2:00pm")
          subject.print_available_blocks ca, events
        end

        context "the array is empty" do
          it "prints a standard message" do
            expect(stdout).to receive(:puts).with(/No available blocks in this time range/)
            subject.print_available_blocks ca, []
          end
        end

        context "the array is nil" do
          it "prints a standard message" do
            expect(stdout).to receive(:puts).with(/No available blocks in this time range/)
            subject.print_available_blocks ca, nil
          end
        end
      end

      context "passed a Hash of Arrays of Events" do
        let(:events) do
          {
            Date.parse("2018-10-18") => [
              CalendarAssistant::Event.new(GCal::Event.new(summary: "do a thing",
                              start: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 09:00:00")),
                              end: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 10:00:00")))),
            ],
            Date.parse("2018-10-19") => [
                CalendarAssistant::Event.new(GCal::Event.new(summary: "do another thing",
                              start: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 12:30:00")),
                              end: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 14:00:00")))),
            ],
          }
        end

        it "prints a title containing the time zone" do
          expect(stdout).to receive(:puts).with(title_regexp)
          subject.print_available_blocks ca, {}
        end

        it "assumes each hash key is a Date and prints it" do
          events.keys.each do |key|
            expect(key).to receive(:strftime).and_return(key.to_s)
            expect(stdout).to receive(:puts).with(Regexp.new(key.to_s))
          end
          subject.print_available_blocks ca, events
        end

        it "recursively calls #print_available_blocks for each hash value" do
          allow(subject).to receive(:print_available_blocks).and_call_original
          expect(subject).to receive(:print_available_blocks).with(ca, events.values.first, omit_title: true)
          expect(subject).to receive(:print_available_blocks).with(ca, events.values.second, omit_title: true)
          subject.print_available_blocks ca, events
        end
      end
    end
  end
end
