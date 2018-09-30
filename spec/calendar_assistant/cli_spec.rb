describe CalendarAssistant::CLI do
  describe "commands" do
    let(:profile_name) { "work" }
    let(:ca) { instance_double("CalendarAssistant") }
    let(:events) { [instance_double("Event")] }
    let(:out) { double("STDOUT") }
    let(:time_range) { double("time range") }

    before do
      expect(CalendarAssistant).to receive(:new).with(profile_name).and_return(ca)
      allow(CalendarAssistant::CLIHelpers::Out).to receive(:new).and_return(out)
    end

    describe "show" do
      it "calls find_events by default for today" do
        expect(CalendarAssistant::CLIHelpers).to receive(:parse_datespec).with("today").and_return(time_range)
        expect(ca).to receive(:find_events).
                        with(time_range).
                        and_return(events)
        expect(out).to receive(:print_events).with(ca, events, anything)

        CalendarAssistant::CLI.start ["show", profile_name]
      end

      it "calls find_events with the range returned from parse_datespec" do
        expect(CalendarAssistant::CLIHelpers).to receive(:parse_datespec).with("user-datespec").and_return(time_range)
        expect(ca).to receive(:find_events).
                        with(time_range).
                        and_return(events)
        expect(out).to receive(:print_events).with(ca, events, anything)

        CalendarAssistant::CLI.start ["show", profile_name, "user-datespec"]
      end
    end

    describe "location" do
      it "calls find_location_events by default for today" do
        expect(CalendarAssistant::CLIHelpers).to receive(:parse_datespec).with("today").and_return(time_range)
        expect(ca).to receive(:find_location_events).
                        with(time_range).
                        and_return(events)
        expect(out).to receive(:print_events).with(ca, events, anything)

        CalendarAssistant::CLI.start ["location", profile_name]
      end

      it "calls find_location_events with the range returned from parse_datespec" do
        expect(CalendarAssistant::CLIHelpers).to receive(:parse_datespec).with("user-datespec").and_return(time_range)
        expect(ca).to receive(:find_location_events).
                        with(time_range).
                        and_return(events)
        expect(out).to receive(:print_events).with(ca, events, anything)

        CalendarAssistant::CLI.start ["location", profile_name, "user-datespec"]
      end
    end

    describe "location-set" do
      it "calls create_location_event by default for today" do
        expect(CalendarAssistant::CLIHelpers).to receive(:parse_datespec).with("today").and_return(time_range)
        expect(ca).to receive("create_location_event").
                        with(time_range, "Palo Alto").
                        and_return({})

        CalendarAssistant::CLI.start ["location-set", profile_name, "Palo Alto"]
      end

      it "calls create_location_event with the range returned from parse_datespec" do
        expect(CalendarAssistant::CLIHelpers).to receive(:parse_datespec).with("user-datespec").and_return(time_range)
        expect(ca).to receive("create_location_event").
                        with(time_range, "Palo Alto").
                        and_return({})

        CalendarAssistant::CLI.start ["location-set", profile_name, "Palo Alto", "user-datespec"]
      end
    end

    describe "join" do
      before do
        allow(out).to receive(:puts)
        allow(out).to receive(:print_events)
      end

      context "default behavior" do
        it "calls #find_events with a small time range around now" do
          expect(CalendarAssistant::CLIHelpers).to receive(:find_av_uri).with(ca, "now")

          CalendarAssistant::CLI.start ["join", profile_name]
        end
      end

      context "given a time" do
        it "calls #find_events with a small time range around that time" do
          expect(CalendarAssistant::CLIHelpers).to receive(:find_av_uri).with(ca, "five minutes from now")

          CalendarAssistant::CLI.start ["join", profile_name, "five minutes from now"]
        end
      end

      context "when a videoconference URI is found" do
        let(:url) { "https://pivotal.zoom.us/j/123456789" }
        let(:event) { instance_double("Event") }

        before do
          allow(CalendarAssistant::CLIHelpers).to receive(:find_av_uri).and_return([event, url])
        end

        it "prints the event" do
          expect(out).to receive(:print_events).with(ca, event, anything)

          CalendarAssistant::CLI.start ["join", profile_name, "--print"]
        end

        context "with --print option" do
          it "prints the meeting URL" do
            expect(out).to receive(:puts).with(url)

            CalendarAssistant::CLI.start ["join", profile_name, "--print"]
          end
        end

        context "by default" do
          it "launches the meeting URL in your browser" do
            expect(out).to receive(:launch).with(url)

            CalendarAssistant::CLI.start ["join", profile_name]
          end
        end
      end
    end
  end
end
