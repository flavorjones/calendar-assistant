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

  describe CalendarAssistant::CLI::Helpers::Out do
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

    describe "#prompt" do
      it "should have tests"
    end

    describe "#print_now!" do
      freeze_time

      let(:event) { CalendarAssistant::Event.new(GCal::Event.new start: GCal::EventDateTime.new(date_time: start_time)) }
      let(:now) { instance_double("Event<now>") }

      before do
        allow(CalendarAssistant::CLI::Helpers).to receive(:now).and_return(now)
      end

      context "having not printed yet" do
        let(:printed) { false }

        context "event start time is earlier than now" do
          let(:start_time) { Time.now - 1.minute }

          it "does not print and returns false" do
            expect(subject).not_to receive(:event_description)
            rval = subject.print_now!(ca, event, printed)
            expect(rval).to be_falsey
          end
        end

        context "event start time is later than now but on a different day" do
          let(:start_time) { Time.now + 1.day + 1.minute }

          it "does not print and returns false" do
            expect(subject).not_to receive(:event_description)
            rval = subject.print_now!(ca, event, printed)
            expect(rval).to be_falsey
          end
        end

        context "event start time is later than now" do
          let(:start_time) { Time.now + 1.minute }

          it "prints and returns true" do
            expect(subject).to receive(:event_description).with(now)
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
            expect(subject).not_to receive(:event_description).with(now)
            rval = subject.print_now!(ca, event, printed)
            expect(rval).to be_truthy
          end
        end
      end
    end

    describe "#print_events" do
      let(:calendar) { instance_double("Calendar") }
      let(:calendar_id) { "calendar-id" }
      let(:calendar_time_zone) { "calendar/time/zone" }
      let(:er) { instance_double("EventRepository") }
      let(:title_regexp) { Regexp.new("#{calendar_id}.*#{calendar_time_zone}") }
      let(:config) { CalendarAssistant::Config.new options: config_options }
      let(:config_options) { Hash.new }

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
        allow(ca).to receive(:config).and_return(config)
        allow(calendar).to receive(:id).and_return(calendar_id)
        allow(calendar).to receive(:time_zone).and_return(calendar_time_zone)
        allow(subject).to receive(:event_description)
        allow(stdout).to receive(:puts)
        allow(er).to receive(:calendar).and_return(calendar)
      end

      context "passed a single Event" do
        let(:event_set) { EventSet.new(er, event) }

        it "prints a title containing the cal id and time zone" do
          expect(stdout).to receive(:puts).with(title_regexp)
          subject.print_events ca, event_set
        end

        context "passed option omit_title:true" do
          it "does not print a title" do
            expect(stdout).not_to receive(:puts).with(title_regexp)
            subject.print_events ca, event_set, omit_title: true
          end
        end

        it "prints the event description" do
          expect(subject).to receive(:event_description).with(event).and_return("event-description")
          expect(stdout).to receive(:puts).with("event-description")
          subject.print_events ca, event_set
        end
      end

      context "passed an Array of Events" do
        let(:event_set) { EventSet.new(er, events) }

        it "prints a title containing the cal id and time zone" do
          expect(stdout).to receive(:puts).with(title_regexp)
          subject.print_events ca, event_set
        end

        it "calls #print_now! before each event" do
          expect(subject).to receive(:print_now!).exactly(events.length).times
          subject.print_events ca, event_set
        end

        it "calls puts with event descriptions for each Event" do
          events.each do |event|
            expect(subject).to receive(:event_description).with(event).and_return(event.summary)
            expect(stdout).to receive(:puts).with(event.summary)
          end
          subject.print_events ca, event_set
        end

        context "option 'commitments'" do
          let(:config_options) { { CalendarAssistant::Config::Keys::Options::COMMITMENTS => true } }

          it "omits events that are not a commitment" do
            allow(events.first).to receive(:commitment?).and_return(true)
            allow(events.last).to receive(:commitment?).and_return(false)

            expect(subject).to receive(:event_description).with(events.first)
            expect(subject).not_to receive(:event_description).with(events.last)

            subject.print_events ca, event_set
          end
        end

        context "the array is empty" do
          it "prints a standard message" do
            expect(stdout).to receive(:puts).with("No events in this time range.")
            subject.print_events ca, EventSet.new(er, [])
          end
        end

        context "the array is nil" do
          it "prints a standard message" do
            expect(stdout).to receive(:puts).with("No events in this time range.")
            subject.print_events ca, EventSet.new(er, nil)
          end
        end
      end

      context "passed a Hash of Arrays of Events" do
        it "prints a title containing the cal id and time zone" do
          expect(stdout).to receive(:puts).with(title_regexp)
          subject.print_events ca, EventSet.new(er, {})
        end

        it "prints each hash key capitalized" do
          expect(stdout).to receive(:puts).with(/First:/)
          expect(stdout).to receive(:puts).with(/Second:/)
          subject.print_events ca, EventSet.new(er, {first: [events.first], second: [events.second]})
        end

        it "recursively calls #print_events for each hash value" do
          allow(subject).to receive(:print_events).and_call_original
          expect(subject).to receive(:print_events).with(ca, EventSet.new(er, [events.first]), omit_title: true)
          expect(subject).to receive(:print_events).with(ca, EventSet.new(er, [events.second]), omit_title: true)
          subject.print_events ca, EventSet.new(er, {first: [events.first], second: [events.second]})
        end
      end
    end

    describe "#print_available_blocks" do
      let(:calendar) { instance_double("Calendar") }
      let(:calendar_id) { "calendar-id" }
      let(:calendar_time_zone) { ENV['TZ'] }
      let(:config) { CalendarAssistant::Config.new options: config_options }
      let(:config_options) { Hash.new }
      let(:er) { instance_double("EventRepository") }
      let(:event_set) { EventSet.new er, events }

      before do
        allow(ca).to receive(:config).and_return(config)
        allow(calendar).to receive(:id).and_return(calendar_id)
        allow(calendar).to receive(:time_zone).and_return(calendar_time_zone)
        allow(subject).to receive(:event_description)
        allow(stdout).to receive(:puts)
        allow(er).to receive(:calendar).and_return(calendar)
        allow(ca).to receive(:event_repository).and_return(er)
      end

      context "passed an Array of Events" do
        let(:events) do
          in_tz calendar_time_zone do
            [
              CalendarAssistant::Event.new(GCal::Event.new(summary: "do a thing",
                                                           start: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 09:00:00")),
                                                           end: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 10:00:00")))),
              CalendarAssistant::Event.new(GCal::Event.new(summary: "do another thing",
                                                           start: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 12:30:00")),
                                                           end: GCal::EventDateTime.new(date_time: Time.parse("2018-10-18 14:00:00")))),
            ]
          end
        end

        it "prints a title containing the calendar id" do
          expect(stdout).to receive(:puts).with(/#{calendar_id}/)
          subject.print_available_blocks ca, event_set
        end

        it "prints a subtitle stating search duration" do
          duration = ChronicDuration.output(ChronicDuration.parse(ca.config.setting(CalendarAssistant::Config::Keys::Settings::MEETING_LENGTH)))
          expect(stdout).to receive(:puts).with(/at least #{duration} long/)
          subject.print_available_blocks ca, event_set
        end

        it "prints a subtitle stating intraday range and time zone" do
          expect(stdout).to receive(:puts).with(/\b#{ca.config.setting(CalendarAssistant::Config::Keys::Settings::START_OF_DAY)}\b.*\b#{ca.config.setting(CalendarAssistant::Config::Keys::Settings::END_OF_DAY)}\b.*\b#{calendar_time_zone}\b/)
          subject.print_available_blocks ca, event_set
        end

        context "passed option omit_title:true" do
          it "does not print a title" do
            expect(stdout).not_to receive(:puts).with(/#{calendar_id}/)
            subject.print_available_blocks ca, event_set, omit_title: true
          end
        end

        it "prints out the time range and time zone of each free block" do
          expect(stdout).to receive(:puts).with(/ •  9:00am - 10:00am \+12.*(1h)/)
          expect(stdout).to receive(:puts).with(/ • 12:30pm -  2:00pm \+12.*(1h 30m)/)
          subject.print_available_blocks ca, event_set
        end

        context "the array is empty" do
          let(:events) { Array.new }

          it "prints a standard message" do
            expect(stdout).to receive(:puts).with(/No available blocks in this time range/)
            subject.print_available_blocks ca, event_set
          end
        end

        context "the array is nil" do
          let(:events) { nil }

          it "prints a standard message" do
            expect(stdout).to receive(:puts).with(/No available blocks in this time range/)
            subject.print_available_blocks ca, event_set
          end
        end

        context "run with multiple attendees" do
          let(:config_options) { {CalendarAssistant::Config::Keys::Options::ATTENDEES => "foo@example.com,bar@example.com"} }
          let(:calendar_time_zone) { "America/Los_Angeles" }
          let(:calendar2) { instance_double("Calendar(2)") }
          let(:er2) { instance_double("EventRepository(2)") }

          before do
            allow(calendar).to receive(:id).and_return("foo@example.com")
            allow(calendar).to receive(:time_zone).and_return(calendar_time_zone)
            allow(er).to receive(:calendar).and_return(calendar)
            allow(ca).to receive(:event_repository).with("foo@example.com").and_return(er)

            allow(calendar2).to receive(:id).and_return("bar@example.com")
            allow(calendar2).to receive(:time_zone).and_return("America/New_York")
            allow(er2).to receive(:calendar).and_return(calendar2)
            allow(ca).to receive(:event_repository).with("bar@example.com").and_return(er2)
          end

          it "prints a title containing the calendar id" do
            expect(stdout).to receive(:puts).with(/foo@example.com, bar@example.com/)
            subject.print_available_blocks ca, event_set
          end

          it "prints a subtitle stating intraday range and time zone for each time zone" do
            expect(stdout).to receive(:puts).with(/\b#{ca.config.setting(CalendarAssistant::Config::Keys::Settings::START_OF_DAY)}\b.*\b#{ca.config.setting(CalendarAssistant::Config::Keys::Settings::END_OF_DAY)}\b.*\b#{calendar.time_zone}\b/)
            expect(stdout).to receive(:puts).with(/\b#{ca.config.setting(CalendarAssistant::Config::Keys::Settings::START_OF_DAY)}\b.*\b#{ca.config.setting(CalendarAssistant::Config::Keys::Settings::END_OF_DAY)}\b.*\b#{calendar2.time_zone}\b/)
            subject.print_available_blocks ca, event_set
          end

          it "prints out the time range and time zone of each free block for each time zone" do
            expect(stdout).to receive(:puts).with(" •  9:00am - 10:00am PDT / 12:00pm -  1:00pm EDT#{Rainbow(" (1h)").italic}")
            expect(stdout).to receive(:puts).with(" • 12:30pm -  2:00pm PDT /  3:30pm -  5:00pm EDT#{Rainbow(" (1h 30m)").italic}")
            subject.print_available_blocks ca, event_set
          end

          context "but the attendees are in the same time zone" do
            let(:calendar_time_zone) { "America/New_York" }

            before do
              allow(calendar2).to receive(:time_zone).and_return("America/Toronto")
            end

            it "prints out the time range just for each unique time zone" do
              expect(stdout).to receive(:puts).with(" •  9:00am - 10:00am EDT#{Rainbow(" (1h)").italic}")
              expect(stdout).to receive(:puts).with(" • 12:30pm -  2:00pm EDT#{Rainbow(" (1h 30m)").italic}")
              subject.print_available_blocks ca, event_set
            end
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

        it "prints a title containing the calendar id" do
          expect(stdout).to receive(:puts).with(/#{calendar_id}/)
          subject.print_available_blocks ca, event_set
        end

        it "assumes each hash key is a Date and prints it" do
          events.keys.each do |key|
            expect(key).to receive(:strftime).and_return(key.to_s)
            expect(stdout).to receive(:puts).with(Regexp.new(key.to_s))
          end
          subject.print_available_blocks ca, event_set
        end

        it "recursively calls #print_available_blocks for each hash value" do
          allow(subject).to receive(:print_available_blocks).and_call_original
          expect(subject).to receive(:print_available_blocks).with(ca, EventSet.new(er, events.values.first), omit_title: true)
          expect(subject).to receive(:print_available_blocks).with(ca, EventSet.new(er, events.values.second), omit_title: true)
          subject.print_available_blocks ca, event_set
        end
      end
    end

    describe "#event_description" do
      it "needs a test"
    end

    describe "#event_date_description" do
      it "needs a test"
    end
  end
end
