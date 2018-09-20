describe CalendarAssistant::CLI do
  describe CalendarAssistant::CLIHelpers do
    it "test time_or_time_range"
    it "test now"

    describe CalendarAssistant::CLIHelpers::Out do
      it "test print_now!"
      it "test print_events"
      it "test puts"
      it "test launch"
    end
  end

  describe "commands" do
    around do |example|
      # freeze time so we can mock with Chronic strings
      Timecop.freeze(Time.local(2018, 7, 13, 12, 1, 1)) do
        example.run
      end
    end
    
    let(:profile_name) { "work" }
    let(:ca) { instance_double("CalendarAssistant") }
    let(:events) { [instance_double("Event")] }
    let(:out) { double("STDOUT") }

    before do
      expect(CalendarAssistant).to receive(:new).with(profile_name).and_return(ca)
      allow(CalendarAssistant::CLIHelpers::Out).to receive(:new).and_return(out)
    end
          
    describe "show" do
      context "with no datespec" do
        it "calls find_events for today" do
          expect(ca).to receive(:find_events).
                          with(Chronic.parse("today")).
                          and_return(events)
          expect(out).to receive(:print_events).with(ca, events, anything)

          CalendarAssistant::CLI.start ["show", profile_name]
        end
      end

      context "with a date" do
        it "calls find_events with the right range" do
          expect(ca).to receive(:find_events).
                          with(Chronic.parse("tomorrow")).
                          and_return(events)
          expect(out).to receive(:print_events).with(ca, events, anything)

          CalendarAssistant::CLI.start ["show", profile_name, "tomorrow"]
        end
      end

      context "with a date range" do
        it "calls find_events with the right range" do
          expect(ca).to receive(:find_events).
                          with(Chronic.parse("tomorrow")..Chronic.parse("two days from now")).
                          and_return(events)
          expect(out).to receive(:print_events).with(ca, events, anything)

          CalendarAssistant::CLI.start ["show", profile_name, "tomorrow...two days from now"]
        end
      end
    end

    describe "location" do
      describe "show" do
        context "with no datespec" do
          it "calls find_location_events for today" do
            expect(ca).to receive(:find_location_events).
                            with(Chronic.parse("today")).
                            and_return(events)
            expect(out).to receive(:print_events).with(ca, events, anything)

            CalendarAssistant::CLI.start ["location", "show", profile_name]
          end
        end

        context "with a date" do
          it "calls find_location_events with the right range" do
            expect(ca).to receive(:find_location_events).
                            with(Chronic.parse("tomorrow")).
                            and_return(events)
            expect(out).to receive(:print_events).with(ca, events, anything)

            CalendarAssistant::CLI.start ["location", "show", profile_name, "tomorrow"]
          end
        end

        context "with a date range" do
          it "calls find_location_events with the right range" do
            expect(ca).to receive(:find_location_events).
                            with(Chronic.parse("tomorrow")..Chronic.parse("two days from now")).
                            and_return(events)
            expect(out).to receive(:print_events).with(ca, events, anything)

            CalendarAssistant::CLI.start ["location", "show", profile_name, "tomorrow...two days from now"]
          end
        end
      end

      describe "set" do
        context "with no datespec" do
          it "calls find_events for today" do
            expect(ca).to receive("create_location_event").
                            with(Chronic.parse("today"), "Palo Alto").
                            and_return({})

            CalendarAssistant::CLI.start ["location", "set", profile_name, "Palo Alto"]
          end
        end

        context "for a date" do
          it "calls create_location_event with the right arguments" do
            expect(ca).to receive("create_location_event").
                            with(Chronic.parse("tomorrow"), "Palo Alto").
                            and_return({})

            CalendarAssistant::CLI.start ["location", "set", profile_name, "Palo Alto", "tomorrow"]
          end
        end

        context "for a date range with spaces" do
          it "calls create_location_event with the right arguments" do
            expect(ca).to receive("create_location_event").
                            with(Chronic.parse("tomorrow")..(Chronic.parse("three days from now") + 1.day).beginning_of_day,
                                 "Palo Alto").
                            and_return({})

            CalendarAssistant::CLI.start ["location", "set", profile_name, "Palo Alto", "tomorrow ... three days from now"]
          end
        end

        context "for a date range without spaces" do
          it "calls create_location_event with the right arguments" do
            expect(ca).to receive("create_location_event").
                            with(Chronic.parse("tomorrow")..(Chronic.parse("three days from now") + 1.day).beginning_of_day,
                                 "Palo Alto").
                            and_return({})

            CalendarAssistant::CLI.start ["location", "set", profile_name, "Palo Alto", "tomorrow...three days from now"]
          end
        end
      end
    end

    describe "join" do
      before do
        allow(out).to receive(:puts)
      end

      it "calls #find_current_av_url" do
        expect(ca).to receive(:find_current_av_url)

        CalendarAssistant::CLI.start ["join", profile_name]
      end

      context "when there is a URL" do
        let(:url) { "https://pivotal.zoom.us/j/123456789" }

        before do
          expect(ca).to receive(:find_current_av_url).
                          and_return(url)
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
