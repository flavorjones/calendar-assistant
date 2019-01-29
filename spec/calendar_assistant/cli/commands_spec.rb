describe CalendarAssistant::CLI::Commands do
  shared_examples "a command" do |options|
    options ||= {}

    it {expect {described_class.start [command, "-h"]}.to output(/Usage:/).to_stdout}

    if options[:argc] && options[:argc] > 0
      context "with no argument" do
        it "should output help test" do
          expect {described_class.start [command]}.to output(/Usage:/).to_stdout
        end
      end
    end

    if options[:profile]
      it "wraps commands #in_env" do
        expect(ca).to receive(:in_env).and_return(0)
        if options[:profile].is_a?(Array)
          described_class.start([command] + options[:profile])
        else
          described_class.start([command])
        end
      end
    end
  end

  let(:ca) {instance_double("CalendarAssistant")}
  let(:er) {instance_double("EventRepository")}
  let(:events) {[instance_double("Event")]}
  let(:event_set) {CalendarAssistant::EventSet.new er, events}
  let(:out) {double("STDOUT")}
  let(:time_range) {double("time range")}
  let(:config) {CalendarAssistant::CLI::Config.new options: config_options }
  let(:config_options) {Hash.new}

  let(:service) {instance_double("CalendarService")}
  let(:token_store) {instance_double("CalendarAssistant::Config::TokenStore")}
  let(:authorizer) {instance_double("Authorizer")}

  before do
    allow(CalendarAssistant::CLI::Authorizer).to receive(:new).and_return(authorizer)
    allow(config).to receive(:token_store).and_return(token_store)
    allow(config).to receive(:profile_name).and_return("profile-name")
    allow(authorizer).to receive(:service).and_return(service)
    allow(CalendarAssistant::Config).to receive(:new).and_return(config)
    allow(CalendarAssistant).to receive(:new).with(config, service: service).and_return(ca)
    allow(CalendarAssistant::CLI::Printer).to receive(:new).and_return(out)
    allow(ca).to receive(:in_env).and_yield
  end

  describe "version" do
    let(:command) {"version"}
    it_behaves_like "a command"

    it "outputs the version number of calendar-assistant" do
      expect(out).to receive(:puts).with(CalendarAssistant::VERSION)

      described_class.start [command]
    end
  end

  describe "config" do
    let(:command) {"config"}
    it_behaves_like "a command"

    let(:generator) {instance_double(TOML::Generator)}

    it "prints out config settings" do
      expect(CalendarAssistant::Config).to receive(:new).with(no_args).and_return(config)
      expect(config).to receive(:settings).and_return({"my" => "settings"})
      allow(TOML::Generator).to receive(:new).with({CalendarAssistant::Config::Keys::SETTINGS => {"my" => "settings"}}).and_return(generator)
      expect(generator).to receive(:body).and_return("body")
      expect(out).to receive(:puts).with("body")

      described_class.start [command]
    end
  end

  describe "setup" do
    let(:command) {"setup"}
    it_behaves_like "a command"

    it "should have a test"
  end

  describe "authorize" do
    let(:command) {"authorize"}
    it_behaves_like "a command", argc: 1

    it "should have a test"
  end

  describe "lint" do
    let(:command) { "lint" }
    it_behaves_like "a command", profile: true

    it "calls find_events by default for today" do
      expect(CalendarAssistant::CLI::Helpers).to receive(:parse_datespec).with("today").and_return(time_range)
      expect(ca).to receive(:lint_events).
          with(time_range).
          and_return(event_set)

      expect(out).to receive(:print_events).with(ca, event_set, presenter_class: CalendarAssistant::CLI::LinterEventSetPresenter)

      described_class.start [command]
    end
  end

  describe "show" do
    let(:command) {"show"}
    it_behaves_like "a command", profile: true

    it "calls find_events by default for today" do
      expect(CalendarAssistant::CLI::Helpers).to receive(:parse_datespec).with("today").and_return(time_range)
      expect(ca).to receive(:find_events).
          with(time_range).
          and_return(event_set)
      expect(out).to receive(:print_events).with(ca, event_set)

      described_class.start [command]
    end

    it "calls find_events with the range returned from parse_datespec" do
      expect(CalendarAssistant::CLI::Helpers).to receive(:parse_datespec).with("user-datespec").and_return(time_range)
      expect(ca).to receive(:find_events).
          with(time_range).
          and_return(event_set)
      expect(out).to receive(:print_events).with(ca, event_set)

      described_class.start [command, "user-datespec"]
    end

    it "uses a specified profile" do
      expect(CalendarAssistant::Config).to receive(:new).
          with(options: hash_including(CalendarAssistant::Config::Keys::Settings::PROFILE => "work")).
          and_return(config)

      allow(ca).to receive(:find_events)
      allow(out).to receive(:print_events)

      described_class.start [command, "-p", "work"]
    end

    context "given another person's calendar id" do
      let(:config_options) do
        {
            CalendarAssistant::Config::Keys::Options::CALENDARS => "somebody@example.com"
        }
      end

      it "shows another person's day" do
        expect(CalendarAssistant::Config).to receive(:new).
            with(options: hash_including(config_options)).
            and_return(config)
        allow(ca).to receive(:find_events)
        allow(out).to receive(:print_events)

        described_class.start [command, "-a", "somebody@example.com"]
      end
    end
  end

  describe "location" do
    let(:command) {"location"}
    it_behaves_like "a command", profile: true

    it "calls find_location_events by default for today" do
      expect(CalendarAssistant::CLI::Helpers).to receive(:parse_datespec).with("today").and_return(time_range)
      expect(ca).to receive(:find_location_events).
          with(time_range).
          and_return(event_set)
      expect(out).to receive(:print_events).with(ca, event_set)

      described_class.start [command]
    end

    it "calls find_location_events with the range returned from parse_datespec" do
      expect(CalendarAssistant::CLI::Helpers).to receive(:parse_datespec).with("user-datespec").and_return(time_range)
      expect(ca).to receive(:find_location_events).
          with(time_range).
          and_return(event_set)
      expect(out).to receive(:print_events).with(ca, event_set)

      described_class.start [command, "user-datespec"]
    end

    it "uses a specified profile" do
      expect(CalendarAssistant::Config).to receive(:new).
          with(options: hash_including(CalendarAssistant::Config::Keys::Settings::PROFILE => "work")).
          and_return(config)

      allow(ca).to receive(:find_location_events)
      allow(out).to receive(:print_events)

      described_class.start [command, "-p", "work"]
    end

  end

  describe "location-set" do
    let(:command) {"location-set"}
    it_behaves_like "a command", argc: 1, profile: ["here"]
    let(:event_set) {CalendarAssistant::EventSet.new(er, {})}

    it "calls create_location_event by default for today" do
      expect(CalendarAssistant::CLI::Helpers).to receive(:parse_datespec).with("today").and_return(time_range)
      expect(ca).to receive("create_location_event").
          with(time_range, "Palo Alto").
          and_return(event_set)
      expect(out).to receive(:print_events).with(ca, event_set)

      described_class.start [command, "Palo Alto"]
    end

    it "calls create_location_event with the range returned from parse_datespec" do
      expect(CalendarAssistant::CLI::Helpers).to receive(:parse_datespec).with("user-datespec").and_return(time_range)
      expect(ca).to receive("create_location_event").
          with(time_range, "Palo Alto").
          and_return(event_set)
      expect(out).to receive(:print_events).with(ca, event_set)

      described_class.start [command, "Palo Alto", "user-datespec"]
    end

    it "uses a specified profile" do
      expect(CalendarAssistant::Config).to receive(:new).
          with(options: hash_including(CalendarAssistant::Config::Keys::Settings::PROFILE => "work")).
          and_return(config)

      allow(ca).to receive(:create_location_event).and_return(event_set)
      allow(out).to receive(:print_events)

      described_class.start [command, "-p", "work", "Palo Alto"]
    end

    describe "visibility" do
      describe "public" do
        it "allows visibility to be set" do
          expect(CalendarAssistant::Config).to receive(:new).
            with(options: hash_including(CalendarAssistant::Config::Keys::Settings::VISIBILITY => "public")).
            and_return(config)

          allow(ca).to receive(:create_location_event).and_return(event_set)
          allow(out).to receive(:print_events)

          described_class.start [command, "--visibility", "public", "Cocomo"]
        end
      end
    end
  end

  describe "join" do
    let(:event_set) {CalendarAssistant::EventSet.new(er)}

    before do
      allow(out).to receive(:puts)
      allow(out).to receive(:print_events)
      allow(CalendarAssistant::Config).to receive(:new).
          with(options: hash_including(CalendarAssistant::Config::Keys::Options::JOIN => true)).
          and_return(config)
    end

    let(:command) {"join"}
    it_behaves_like "a command", profile: true

    context "default behavior" do
      it "calls #find_events with a small time range around now" do
        expect(CalendarAssistant::CLI::Helpers).to receive(:find_av_uri).with(ca, "now").and_return(event_set)

        described_class.start [command]
      end

      it "uses a specified profile" do
        expect(CalendarAssistant::Config).to receive(:new).
            with(options: hash_including({
                CalendarAssistant::Config::Keys::Options::JOIN => true,
                CalendarAssistant::Config::Keys::Settings::PROFILE => "work",
            })).at_least(:once).and_return(config)

        allow(ca).to receive(:find_events).and_return(CalendarAssistant::EventSet.new(er, []))

        described_class.start [command, "-p", "work"]
      end
    end

    context "given a time" do
      it "calls #find_events with a small time range around that time" do
        expect(CalendarAssistant::CLI::Helpers).to receive(:find_av_uri).with(ca, "five minutes from now").and_return([event_set, ""])

        described_class.start [command, "five minutes from now"]
      end
    end

    context "when a videoconference URI is found" do
      let(:url) {"https://pivotal.zoom.us/j/123456789"}
      let(:event) {instance_double("Event")}
      let(:event_set) {CalendarAssistant::EventSet.new er, event}

      before do
        allow(CalendarAssistant::CLI::Helpers).to receive(:find_av_uri).and_return([event_set, url])
        allow(out).to receive(:launch).with(url)
      end

      it "prints the event" do
        expect(out).to receive(:print_events).with(ca, event_set)

        described_class.start [command]
      end

      it "prints the meeting URL" do
        expect(out).to receive(:puts).with(url)

        described_class.start [command]
      end

      context "by default" do
        it "launches the meeting URL in your browser" do
          expect(out).to receive(:launch).with(url)

          described_class.start [command]
        end
      end

      context "with --no-join" do
        it "does not launch the meeting URL in your browser" do
          expect(CalendarAssistant::Config).to receive(:new).
              with(options: hash_including(CalendarAssistant::Config::Keys::Options::JOIN => false)).
              at_least(:once).
              and_return(config)
          expect(out).not_to receive(:launch).with(url)

          described_class.start [command, "--no-join"]
        end
      end
    end
  end

  describe "availability" do
    let(:command) {"availability"}
    it_behaves_like "a command", profile: true

    it "calls availability by default for today" do
      expect(CalendarAssistant::CLI::Helpers).to receive(:parse_datespec).with("today").and_return(time_range)
      expect(ca).to receive(:availability).
          with(time_range).
          and_return(event_set)
      expect(out).to receive(:print_available_blocks).with(ca, event_set)

      described_class.start [command]
    end

    it "calls availability with the range returned from parse_datespec" do
      expect(CalendarAssistant::CLI::Helpers).to receive(:parse_datespec).with("user-datespec").and_return(time_range)
      expect(ca).to receive(:availability).
          with(time_range).
          and_return(event_set)
      expect(out).to receive(:print_available_blocks).with(ca, event_set)

      described_class.start [command, "user-datespec"]
    end

    it "uses a specified profile" do
      expect(CalendarAssistant::Config).to receive(:new).
          with(options: hash_including(CalendarAssistant::Config::Keys::Settings::PROFILE => "work")).
          and_return(config)

      allow(ca).to receive(:availability)
      allow(out).to receive(:print_available_blocks)

      described_class.start [command, "-p", "work"]
    end

    it "uses a specified duration" do
      expect(CalendarAssistant::Config).to receive(:new).
          with(options: hash_including(CalendarAssistant::Config::Keys::Settings::MEETING_LENGTH => "30min")).
          and_return(config)

      allow(ca).to receive(:availability)
      allow(out).to receive(:print_available_blocks)

      described_class.start [command, "-l", "30min"]
    end

    it "uses a specified start time" do
      expect(CalendarAssistant::Config).to receive(:new).
          with(options: hash_including(CalendarAssistant::Config::Keys::Settings::START_OF_DAY => "8:30am")).
          and_return(config)

      allow(ca).to receive(:availability)
      allow(out).to receive(:print_available_blocks)

      described_class.start [command, "-s", "8:30am"]
    end

    it "uses a specified end time" do
      expect(CalendarAssistant::Config).to receive(:new).
          with(options: hash_including(CalendarAssistant::Config::Keys::Settings::END_OF_DAY => "6:30pm")).
          and_return(config)

      allow(ca).to receive(:availability)
      allow(out).to receive(:print_available_blocks)

      described_class.start [command, "-e", "6:30pm"]
    end

    it "looks up another person's availability" do
      expect(CalendarAssistant::Config).to receive(:new).
          with(options: hash_including(CalendarAssistant::Config::Keys::Options::CALENDARS => "somebody@example.com")).
          and_return(config)

      allow(ca).to receive(:availability)
      allow(out).to receive(:print_available_blocks)

      described_class.start [command, "-a", "somebody@example.com"]
    end
  end
end
