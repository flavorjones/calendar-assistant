describe CalendarAssistant::CLI do
  describe "commands" do
    let(:ca) { instance_double("CalendarAssistant") }
    let(:events) { [instance_double("Event")] }
    let(:out) { double("STDOUT") }
    let(:time_range) { double("time range") }
    let(:config) { instance_double("CalendarAssistant::Config") }

    before do
      allow(CalendarAssistant::Config).to receive(:new).with(options: {}).and_return(config)
      expect(CalendarAssistant).to receive(:new).with(config).and_return(ca)
      allow(CalendarAssistant::CLIHelpers::Out).to receive(:new).and_return(out)
    end

    describe "show" do
      it "calls find_events by default for today" do
        expect(CalendarAssistant::CLIHelpers).to receive(:parse_datespec).with("today").and_return(time_range)
        expect(ca).to receive(:find_events).
                        with(time_range).
                        and_return(events)
        expect(out).to receive(:print_events).with(ca, events, anything)

        CalendarAssistant::CLI.start ["show"]
      end

      it "calls find_events with the range returned from parse_datespec" do
        expect(CalendarAssistant::CLIHelpers).to receive(:parse_datespec).with("user-datespec").and_return(time_range)
        expect(ca).to receive(:find_events).
                        with(time_range).
                        and_return(events)
        expect(out).to receive(:print_events).with(ca, events, anything)

        CalendarAssistant::CLI.start ["show", "user-datespec"]
      end

      it "uses a specified profile" do
        expect(CalendarAssistant::Config).to receive(:new).
                                               with(options: {"profile" => "work"}).
                                               and_return(config)

        allow(ca).to receive(:find_events)
        allow(out).to receive(:print_events)

        CalendarAssistant::CLI.start ["show", "-p", "work"]
      end
    end

    describe "location" do
      it "calls find_location_events by default for today" do
        expect(CalendarAssistant::CLIHelpers).to receive(:parse_datespec).with("today").and_return(time_range)
        expect(ca).to receive(:find_location_events).
                        with(time_range).
                        and_return(events)
        expect(out).to receive(:print_events).with(ca, events, anything)

        CalendarAssistant::CLI.start ["location"]
      end

      it "calls find_location_events with the range returned from parse_datespec" do
        expect(CalendarAssistant::CLIHelpers).to receive(:parse_datespec).with("user-datespec").and_return(time_range)
        expect(ca).to receive(:find_location_events).
                        with(time_range).
                        and_return(events)
        expect(out).to receive(:print_events).with(ca, events, anything)

        CalendarAssistant::CLI.start ["location", "user-datespec"]
      end

      it "uses a specified profile" do
        expect(CalendarAssistant::Config).to receive(:new).
                                               with(options: {"profile" => "work"}).
                                               and_return(config)

        allow(ca).to receive(:find_location_events)
        allow(out).to receive(:print_events)

        CalendarAssistant::CLI.start ["location", "-p", "work"]
      end
    end

    describe "location-set" do
      it "calls create_location_event by default for today" do
        expect(CalendarAssistant::CLIHelpers).to receive(:parse_datespec).with("today").and_return(time_range)
        expect(ca).to receive("create_location_event").
                        with(time_range, "Palo Alto").
                        and_return({})
        expect(out).to receive(:print_events).with(ca, {}, anything)

        CalendarAssistant::CLI.start ["location-set", "Palo Alto"]
      end

      it "calls create_location_event with the range returned from parse_datespec" do
        expect(CalendarAssistant::CLIHelpers).to receive(:parse_datespec).with("user-datespec").and_return(time_range)
        expect(ca).to receive("create_location_event").
                        with(time_range, "Palo Alto").
                        and_return({})
        expect(out).to receive(:print_events).with(ca, {}, anything)

        CalendarAssistant::CLI.start ["location-set", "Palo Alto", "user-datespec"]
      end

      it "uses a specified profile" do
        expect(CalendarAssistant::Config).to receive(:new).
                                               with(options: {"profile" => "work"}).
                                               and_return(config)

        allow(ca).to receive(:create_location_event).and_return({})
        allow(out).to receive(:print_events)

        CalendarAssistant::CLI.start ["location-set", "-p", "work", "Palo Alto"]
      end
    end

    describe "join" do
      before do
        allow(out).to receive(:puts)
        allow(out).to receive(:print_events)
        allow(CalendarAssistant::Config).to receive(:new).
                                              with(options: {"join" => true}).
                                              and_return(config)
      end

      context "default behavior" do
        it "calls #find_events with a small time range around now" do
          expect(CalendarAssistant::CLIHelpers).to receive(:find_av_uri).with(ca, "now")

          CalendarAssistant::CLI.start ["join"]
        end

        it "uses a specified profile" do
          expect(CalendarAssistant::Config).to receive(:new).
                                                 with(options: {"join" => true, "profile" => "work"}).
                                                 and_return(config)

          allow(ca).to receive(:find_events).and_return([])

          CalendarAssistant::CLI.start ["join", "-p", "work"]
        end
      end

      context "given a time" do
        it "calls #find_events with a small time range around that time" do
          expect(CalendarAssistant::CLIHelpers).to receive(:find_av_uri).with(ca, "five minutes from now")

          CalendarAssistant::CLI.start ["join", "five minutes from now"]
        end
      end

      context "when a videoconference URI is found" do
        let(:url) { "https://pivotal.zoom.us/j/123456789" }
        let(:event) { instance_double("Event") }

        before do
          allow(CalendarAssistant::CLIHelpers).to receive(:find_av_uri).and_return([event, url])
          allow(out).to receive(:launch).with(url)
        end

        it "prints the event" do
          expect(out).to receive(:print_events).with(ca, event, anything)

          CalendarAssistant::CLI.start ["join"]
        end

        it "prints the meeting URL" do
          expect(out).to receive(:puts).with(url)

          CalendarAssistant::CLI.start ["join"]
        end

        context "by default" do
          it "launches the meeting URL in your browser" do
            expect(out).to receive(:launch).with(url)

            CalendarAssistant::CLI.start ["join"]
          end
        end

        context "with --no-join" do
          it "does not launch the meeting URL in your browser" do
            expect(CalendarAssistant::Config).to receive(:new).
                                                   with(options: {"join" => false}).
                                                   and_return(config)
            expect(out).not_to receive(:launch).with(url)

            CalendarAssistant::CLI.start ["join", "--no-join"]
          end
        end
      end
    end
  end
end
