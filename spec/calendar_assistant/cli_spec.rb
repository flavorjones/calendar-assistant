describe CalendarAssistant::CLI do
  describe "commands" do
    shared_examples "a command" do |options|
      options ||= {}

      it { expect { CalendarAssistant::CLI.start [command, "-h"] }.to output(/Usage:/).to_stdout }

      if options[:argc] && options[:argc] > 0
        context "with no argument" do
          it "should output help test" do
            expect { CalendarAssistant::CLI.start [command] }.to output(/Usage:/).to_stdout
          end
        end
      end

      if options[:profile]
        it "wraps commands #in_env" do
          expect(ca).to receive(:in_env).and_return(0)
          if options[:profile].is_a?(Array)
            CalendarAssistant::CLI.start([command] + options[:profile])
          else
            CalendarAssistant::CLI.start([command])
          end
        end
      end
    end

    let(:ca) { instance_double("CalendarAssistant") }
    let(:er) { instance_double("EventRepository") }
    let(:events) { [instance_double("Event")] }
    let(:event_set) { CalendarAssistant::EventSet.new er, events }
    let(:out) { double("STDOUT") }
    let(:time_range) { double("time range") }
    let(:config) { instance_double("CalendarAssistant::Config") }
    let(:config_options) { Hash.new }

    before do
      allow(CalendarAssistant::Config).to receive(:new).with(options: {}).and_return(config)
      allow(CalendarAssistant).to receive(:new).with(config).and_return(ca)
      allow(CalendarAssistant::CLIHelpers::Out).to receive(:new).and_return(out)
      allow(ca).to receive(:in_env).and_yield
      allow(config).to receive(:options).and_return(config_options)
    end

    describe "version" do
      let(:command) { "version" }
      it_behaves_like "a command"

      it "outputs the version number of calendar-assistant" do
        expect(out).to receive(:puts).with(CalendarAssistant::VERSION)

        CalendarAssistant::CLI.start [command]
      end
    end

    describe "config" do
      let(:command) { "config" }
      it_behaves_like "a command"

      let(:generator) { instance_double(TOML::Generator) }

      it "prints out config settings" do
        expect(CalendarAssistant::Config).to receive(:new).with(no_args).and_return(config)
        expect(config).to receive(:settings).and_return({"my" => "settings"})
        allow(TOML::Generator).to receive(:new).with({CalendarAssistant::Config::Keys::SETTINGS => {"my" => "settings"}}).and_return(generator)
        expect(generator).to receive(:body).and_return("body")
        expect(out).to receive(:puts).with("body")

        CalendarAssistant::CLI.start [command]
      end
    end

    describe "setup" do
      let(:command) { "setup" }
      it_behaves_like "a command"

      it "should have a test"
    end

    describe "authorize" do
      let(:command) { "authorize" }
      it_behaves_like "a command", argc: 1

      it "should have a test"
    end

    describe "show" do
      let(:command) { "show" }
      it_behaves_like "a command", profile: true

      it "calls find_events by default for today" do
        expect(CalendarAssistant::CLIHelpers).to receive(:parse_datespec).with("today").and_return(time_range)
        expect(ca).to receive(:find_events).
                        with(time_range).
                        and_return(event_set)
        expect(out).to receive(:print_events).with(ca, event_set)

        CalendarAssistant::CLI.start [command]
      end

      it "calls find_events with the range returned from parse_datespec" do
        expect(CalendarAssistant::CLIHelpers).to receive(:parse_datespec).with("user-datespec").and_return(time_range)
        expect(ca).to receive(:find_events).
                        with(time_range).
                        and_return(event_set)
        expect(out).to receive(:print_events).with(ca, event_set)

        CalendarAssistant::CLI.start [command, "user-datespec"]
      end

      it "uses a specified profile" do
        expect(CalendarAssistant::Config).to receive(:new).
                                               with(options: {CalendarAssistant::Config::Keys::Settings::PROFILE => "work"}).
                                               and_return(config)

        allow(ca).to receive(:find_events)
        allow(out).to receive(:print_events)

        CalendarAssistant::CLI.start [command, "-p", "work"]
      end

      context "given another person's calendar id" do
        let(:config_options) do
          {
            CalendarAssistant::Config::Keys::Options::ATTENDEES => "somebody@example.com"
          }
        end

        it "shows another person's day" do
          expect(CalendarAssistant::Config).to receive(:new).
                                                 with(options: config_options).
                                                 and_return(config)
          allow(ca).to receive(:find_events)
          allow(out).to receive(:print_events)

          CalendarAssistant::CLI.start [command, "-a", "somebody@example.com"]
        end
      end
    end

    describe "location" do
      let(:command) { "location" }
      it_behaves_like "a command", profile: true

      it "calls find_location_events by default for today" do
        expect(CalendarAssistant::CLIHelpers).to receive(:parse_datespec).with("today").and_return(time_range)
        expect(ca).to receive(:find_location_events).
                        with(time_range).
                        and_return(event_set)
        expect(out).to receive(:print_events).with(ca, event_set)

        CalendarAssistant::CLI.start [command]
      end

      it "calls find_location_events with the range returned from parse_datespec" do
        expect(CalendarAssistant::CLIHelpers).to receive(:parse_datespec).with("user-datespec").and_return(time_range)
        expect(ca).to receive(:find_location_events).
                        with(time_range).
                        and_return(event_set)
        expect(out).to receive(:print_events).with(ca, event_set)

        CalendarAssistant::CLI.start [command, "user-datespec"]
      end

      it "uses a specified profile" do
        expect(CalendarAssistant::Config).to receive(:new).
                                               with(options: {CalendarAssistant::Config::Keys::Settings::PROFILE => "work"}).
                                               and_return(config)

        allow(ca).to receive(:find_location_events)
        allow(out).to receive(:print_events)

        CalendarAssistant::CLI.start [command, "-p", "work"]
      end
    end

    describe "location-set" do
      let(:command) { "location-set" }
      it_behaves_like "a command", argc: 1, profile: ["here"]
      let(:event_set) { CalendarAssistant::EventSet.new(er, {}) }

      it "calls create_location_event by default for today" do
        expect(CalendarAssistant::CLIHelpers).to receive(:parse_datespec).with("today").and_return(time_range)
        expect(ca).to receive("create_location_event").
                        with(time_range, "Palo Alto").
                        and_return(event_set)
        expect(out).to receive(:print_events).with(ca, event_set)

        CalendarAssistant::CLI.start [command, "Palo Alto"]
      end

      it "calls create_location_event with the range returned from parse_datespec" do
        expect(CalendarAssistant::CLIHelpers).to receive(:parse_datespec).with("user-datespec").and_return(time_range)
        expect(ca).to receive("create_location_event").
                        with(time_range, "Palo Alto").
                        and_return(event_set)
        expect(out).to receive(:print_events).with(ca, event_set)

        CalendarAssistant::CLI.start [command, "Palo Alto", "user-datespec"]
      end

      it "uses a specified profile" do
        expect(CalendarAssistant::Config).to receive(:new).
                                               with(options: {CalendarAssistant::Config::Keys::Settings::PROFILE => "work"}).
                                               and_return(config)

        allow(ca).to receive(:create_location_event).and_return(event_set)
        allow(out).to receive(:print_events)

        CalendarAssistant::CLI.start [command, "-p", "work", "Palo Alto"]
      end
    end

    describe "join" do
      let(:event_set) { CalendarAssistant::EventSet.new(er) }

      before do
        allow(out).to receive(:puts)
        allow(out).to receive(:print_events)
        allow(CalendarAssistant::Config).to receive(:new).
                                              with(options: {CalendarAssistant::Config::Keys::Options::JOIN => true}).
                                              and_return(config)
      end

      let(:command) { "join" }
      it_behaves_like "a command", profile: true

      context "default behavior" do
        it "calls #find_events with a small time range around now" do
          expect(CalendarAssistant::CLIHelpers).to receive(:find_av_uri).with(ca, "now").and_return(event_set)

          CalendarAssistant::CLI.start [command]
        end

        it "uses a specified profile" do
          expect(CalendarAssistant::Config).to receive(:new).
                                                 with(options: {
                                                        CalendarAssistant::Config::Keys::Options::JOIN => true,
                                                        CalendarAssistant::Config::Keys::Settings::PROFILE => "work",
                                                      }).and_return(config)

          allow(ca).to receive(:find_events).and_return(CalendarAssistant::EventSet.new(er, []))

          CalendarAssistant::CLI.start [command, "-p", "work"]
        end
      end

      context "given a time" do
        it "calls #find_events with a small time range around that time" do
          expect(CalendarAssistant::CLIHelpers).to receive(:find_av_uri).with(ca, "five minutes from now").and_return([event_set, ""])

          CalendarAssistant::CLI.start [command, "five minutes from now"]
        end
      end

      context "when a videoconference URI is found" do
        let(:url) { "https://pivotal.zoom.us/j/123456789" }
        let(:event) { instance_double("Event") }
        let(:event_set) { CalendarAssistant::EventSet.new er, event }

        before do
          allow(CalendarAssistant::CLIHelpers).to receive(:find_av_uri).and_return([event_set, url])
          allow(out).to receive(:launch).with(url)
        end

        it "prints the event" do
          expect(out).to receive(:print_events).with(ca, event_set)

          CalendarAssistant::CLI.start [command]
        end

        it "prints the meeting URL" do
          expect(out).to receive(:puts).with(url)

          CalendarAssistant::CLI.start [command]
        end

        context "by default" do
          it "launches the meeting URL in your browser" do
            expect(out).to receive(:launch).with(url)

            CalendarAssistant::CLI.start [command]
          end
        end

        context "with --no-join" do
          it "does not launch the meeting URL in your browser" do
            expect(CalendarAssistant::Config).to receive(:new).
                                                   with(options: {CalendarAssistant::Config::Keys::Options::JOIN => false}).
                                                   and_return(config)
            expect(out).not_to receive(:launch).with(url)

            CalendarAssistant::CLI.start [command, "--no-join"]
          end
        end
      end
    end

    describe "availability" do
      let(:command) { "availability" }
      it_behaves_like "a command", profile: true

      it "calls availability by default for today" do
        expect(CalendarAssistant::CLIHelpers).to receive(:parse_datespec).with("today").and_return(time_range)
        expect(ca).to receive(:availability).
                        with(time_range).
                        and_return(event_set)
        expect(out).to receive(:print_available_blocks).with(ca, event_set)

        CalendarAssistant::CLI.start [command]
      end

      it "calls availability with the range returned from parse_datespec" do
        expect(CalendarAssistant::CLIHelpers).to receive(:parse_datespec).with("user-datespec").and_return(time_range)
        expect(ca).to receive(:availability).
                        with(time_range).
                        and_return(event_set)
        expect(out).to receive(:print_available_blocks).with(ca, event_set)

        CalendarAssistant::CLI.start [command, "user-datespec"]
      end

      it "uses a specified profile" do
        expect(CalendarAssistant::Config).to receive(:new).
                                               with(options: {CalendarAssistant::Config::Keys::Settings::PROFILE => "work"}).
                                               and_return(config)

        allow(ca).to receive(:availability)
        allow(out).to receive(:print_available_blocks)

        CalendarAssistant::CLI.start [command, "-p", "work"]
      end

      it "uses a specified duration" do
        expect(CalendarAssistant::Config).to receive(:new).
                                               with(options: {CalendarAssistant::Config::Keys::Settings::MEETING_LENGTH => "30min"}).
                                               and_return(config)

        allow(ca).to receive(:availability)
        allow(out).to receive(:print_available_blocks)

        CalendarAssistant::CLI.start [command, "-l", "30min"]
      end

      it "uses a specified start time" do
        expect(CalendarAssistant::Config).to receive(:new).
                                               with(options: {CalendarAssistant::Config::Keys::Settings::START_OF_DAY => "8:30am"}).
                                               and_return(config)

        allow(ca).to receive(:availability)
        allow(out).to receive(:print_available_blocks)

        CalendarAssistant::CLI.start [command, "-s", "8:30am"]
      end

      it "uses a specified end time" do
        expect(CalendarAssistant::Config).to receive(:new).
                                               with(options: {CalendarAssistant::Config::Keys::Settings::END_OF_DAY => "6:30pm"}).
                                               and_return(config)

        allow(ca).to receive(:availability)
        allow(out).to receive(:print_available_blocks)

        CalendarAssistant::CLI.start [command, "-e", "6:30pm"]
      end

      it "looks up another person's availability" do
        expect(CalendarAssistant::Config).to receive(:new).
                                               with(options: {CalendarAssistant::Config::Keys::Options::ATTENDEES => "somebody@example.com"}).
                                               and_return(config)

        allow(ca).to receive(:availability)
        allow(out).to receive(:print_available_blocks)

        CalendarAssistant::CLI.start [command, "-a", "somebody@example.com"]
      end
    end
  end
end
