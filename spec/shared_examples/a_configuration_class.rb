shared_examples_for "a configuration class" do
  let(:user_config) { { } }

  describe "#in_env" do
    subject { described_class.new options: config_options }
    let(:config_options) do
      {
          described_class::Keys::Settings::START_OF_DAY => "7am",
          described_class::Keys::Settings::END_OF_DAY => "3pm",
      }
    end

    it "sets beginning and end of workday and restores them" do
      BusinessTime::Config.beginning_of_workday = "6am"
      BusinessTime::Config.end_of_workday = "2pm"
      subject.in_env do
        expect(BusinessTime::Config.beginning_of_workday.hour).to eq(7)
        expect(BusinessTime::Config.end_of_workday.hour).to eq(15)
      end
      expect(BusinessTime::Config.beginning_of_workday.hour).to eq(6)
      expect(BusinessTime::Config.end_of_workday.hour).to eq(14)
    end

    it "exceptionally restores beginning and end of workday" do
      BusinessTime::Config.beginning_of_workday = "6am"
      BusinessTime::Config.end_of_workday = "2pm"
      subject.in_env do
        raise RuntimeError
      rescue
      end
      expect(BusinessTime::Config.beginning_of_workday.hour).to eq(6)
      expect(BusinessTime::Config.end_of_workday.hour).to eq(14)
    end
  end

  describe "#profile_name" do
    let(:options) { Hash.new }
    let(:user_config) { {} }
    subject { described_class.new(options: options, **args) }

    context "a default profile name is not configured" do
      context "no tokens exist" do
        it "raises an exception telling the user to authorize first" do
          expect { subject.profile_name }.to raise_exception(CalendarAssistant::BaseException)
        end
      end

      context "a token exists" do
        let(:user_config) do
          {
              "tokens" => {
                  "arbeit" => "fake-token-1",
                  "play" => "fake-token-2",
              }
          }
        end

        it "returns the first token key (hashes are not always stable)" do
          expect(subject.profile_name).to eq("arbeit")
        end

        it "saves a default the first token key as the default profile in 'settings.profile', hashes are not always stable" do
          subject.profile_name

          new_config = described_class.new(**args)
          expect(new_config.get([described_class::Keys::SETTINGS, described_class::Keys::Settings::PROFILE])).to eq("arbeit")
        end
      end
    end

    context "a default profile name is configured" do
      let(:user_config) do
        {
            "tokens" => {
                "arbeit" => "fake-token-1",
                "play" => "fake-token-2"
            },
            "settings" => {
                "profile" => "other"
            }
        }
      end

      it "returns the configured default profile name" do
        expect(subject.profile_name).to eq("other")
      end

      context "a profile is specified via options" do
        let(:options) { {"profile" => "home"} }

        it "returns the profile specified in the options" do
          expect(subject.profile_name).to eq("home")
        end
      end
    end
  end

  describe "#get" do
    let(:user_config) do
      {
          "size" => "medium",

          "things" => {
              "thing2" => "bar",
              "thing1" => "foo"
          }
      }
    end

    subject { described_class.new(**args) }

    context "the key exists in the user config" do
      context "the value is a scalar" do
        it "returns the value" do
          expect(subject.get("size")).to eq("medium")
          expect(subject.get(["size"])).to eq("medium")

          expect(subject.get("things.thing1")).to eq("foo")
          expect(subject.get(["things", "thing1"])).to eq("foo")

          expect(subject.get("things.thing2")).to eq("bar")
          expect(subject.get(["things", "thing2"])).to eq("bar")
        end
      end

      context "the value is a Hash" do
        it "raises an exception" do
          expect { subject.get("things") }.
              to raise_exception(described_class::AccessingHashAsScalar)
        end
      end
    end

    context "the key does not exist in the user config" do
      it "returns nil" do
        expect(subject.get("nonexistentScalarKey")).to eq(nil)
        expect(subject.get("nonexistentHashKey.nonexistentKey")).to eq(nil)
      end
    end
  end

  describe "#set" do
    let(:user_config) do
      {
          "size" => "medium",

          "things" => {
              "thing1" => "foo",
              "thing2" => "bar"
          }
      }
    end

    subject { described_class.new(**args) }

    context "keys as array" do
      context "the key exists in the user config" do
        it "sets the value in the config" do
          subject.set(["size"], "large")
          expect(subject.get("size")).to eq("large")

          subject.set(["things", "thing1"], "quux")
          expect(subject.get("things.thing1")).to eq("quux")
        end
      end

      context "the key does not exist in the user config" do
        it "sets the value in the config" do
          subject.set(["quantity"], "dozen")
          expect(subject.get("quantity")).to eq("dozen")

          subject.set(["things", "thing3"], "quux")
          expect(subject.get("things.thing3")).to eq("quux")

          subject.set(["nonexistentHashKey", "nonexistentKey"], "such wow")
          expect(subject.get("nonexistentHashKey.nonexistentKey")).to eq("such wow")
        end
      end
    end

    context "keys as strings" do
      context "the key exists in the user config" do
        it "sets the value in the config" do
          subject.set("size", "large")
          expect(subject.get("size")).to eq("large")

          subject.set("things.thing1", "quux")
          expect(subject.get("things.thing1")).to eq("quux")
        end
      end

      context "the key does not exist in the user config" do
        it "sets the value in the config" do
          subject.set("quantity", "dozen")
          expect(subject.get("quantity")).to eq("dozen")

          subject.set("things.thing3", "quux")
          expect(subject.get("things.thing3")).to eq("quux")

          subject.set("nonexistentHashKey.nonexistentKey", "such wow")
          expect(subject.get("nonexistentHashKey.nonexistentKey")).to eq("such wow")
        end
      end
    end
  end

  shared_examples_for "a hash like getter" do
    describe "#defaults" do
      it "has an intelligent default for the duration of a new meeting" do
        expect(subject.public_send(method, "meeting-length")).to eq("30m")
      end

      it "has an intelligent default for the start of the day" do
        expect(subject.public_send(method, "start-of-day")).to eq("9am")
      end

      it "has an intelligent default for the end of the day" do
        expect(subject.public_send(method, "end-of-day")).to eq("6pm")
      end
    end

    describe "#setting" do
      let(:user_config) do
        {
            "settings" =>
                {
                    "only-in-user-config" => "user-config",
                    "in-user-config-and-defaults" => "user-config",
                    "in-user-config-and-options" => "user-config",
                    "everywhere" => "user-config"
                }
        }
      end

      let(:defaults) do
        {
            "only-in-defaults" => "defaults",
            "in-user-config-and-defaults" => "defaults",
            "in-defaults-and-options" => "defaults",
            "everywhere" => "defaults",
        }
      end

      let(:options) do
        {
            "only-in-options" => "options",
            "in-user-config-and-options" => "options",
            "in-defaults-and-options" => "options",
            "everywhere" => "options",
        }
      end

      subject do
        described_class.new **args,
                            defaults: defaults,
                            options: options
      end

      it { expect(subject.public_send(method, "only-in-user-config")).to eq("user-config") }
      it { expect(subject.public_send(method, "only-in-defaults")).to eq("defaults") }
      it { expect(subject.public_send(method, "only-in-options")).to eq("options") }

      it { expect(subject.public_send(method, "in-user-config-and-defaults")).to eq("user-config") }
      it { expect(subject.public_send(method, "in-user-config-and-options")).to eq("options") }
      it { expect(subject.public_send(method, "in-defaults-and-options")).to eq("options") }

      it { expect(subject.public_send(method, "everywhere")).to eq("options") }
    end
  end
  
  it_behaves_like "a hash like getter" do
    let(:method) { :setting }
  end

  it_behaves_like "a hash like getter" do
    let(:method) { :[] }
  end

  describe "#settings" do
    it "returns a hash of user-configurable settings and their values" do
      expected_hash = {}
      described_class::Keys::Settings.constants.each do |constant|
        name = described_class::Keys::Settings.const_get constant
        expect(subject).to receive(:setting).with(name).and_return("value:#{name}")
        expected_hash[name] = "value:#{name}"
      end

      expect(subject.settings).to eq(expected_hash)
    end
  end

  describe "#tokens" do
    context "there are tokens configured in user_config" do
      let(:user_config) do
        {
            "tokens" => {
                "arbeit" => "asdfasdf"
            }
        }
      end

      subject { described_class.new(**args) }

      it "returns the tokens hash" do
        expect(subject.tokens).to eq("arbeit" => "asdfasdf")
      end
    end

    context "there are no tokens configured in user_config" do
      let(:user_config) do
        {
            "things" => {
                "thing1" => "asdfasdf"
            }
        }
      end

      subject { described_class.new(**args) }

      it "returns the tokens hash" do
        expect(subject.tokens).to eq({})
      end
    end
  end

  describe "#token_store" do
    it "returns an object suitable for use as a Google::Auth::TokenStore" do
      expect(subject.token_store).to respond_to(:delete)
      expect(subject.token_store.method(:delete).arity).to eq(1)

      expect(subject.token_store).to respond_to(:load)
      expect(subject.token_store.method(:load).arity).to eq(1)

      expect(subject.token_store).to respond_to(:store)
      expect(subject.token_store.method(:store).arity).to eq(2)
    end
  end

  describe "#attendees" do
    subject { described_class.new options: config_options }

    context "by default" do
      let(:config_options) { Hash.new }
      it { expect(subject.attendees).to eq([described_class::DEFAULT_CALENDAR_ID]) }
    end

    context "passed a single attendee" do
      let(:config_options) { {described_class::Keys::Options::ATTENDEES => "foo@example.com"} }
      it { expect(subject.attendees).to eq(["foo@example.com"]) }
    end

    context "passed multiple attendees" do
      let(:config_options) { {described_class::Keys::Options::ATTENDEES => "foo@example.com,bar@example.com"} }
      it { expect(subject.attendees).to eq(["foo@example.com", "bar@example.com"]) }
    end
  end

  describe "#must_be" do
    subject { described_class.new options: config_options }

    context "by default" do
      let(:config_options) { Hash.new }
      it { expect(subject.attendees).to eq([described_class::DEFAULT_CALENDAR_ID]) }
    end

    context "passed a single must_be" do
      let(:config_options) { {described_class::Keys::Options::MUST_BE => "option1"} }
      it { expect(subject.must_be).to eq(["option1"]) }
    end

    context "passed multiple must_bes" do
      let(:config_options) { {described_class::Keys::Options::MUST_BE => "option1,option2"} }
      it { expect(subject.must_be).to eq(["option1", "option2"]) }
    end
  end

  describe "#must_not_be" do
    subject { described_class.new options: config_options }

    context "by default" do
      let(:config_options) { Hash.new }
      it { expect(subject.attendees).to eq([described_class::DEFAULT_CALENDAR_ID]) }
    end

    context "passed a single must_not_be" do
      let(:config_options) { {described_class::Keys::Options::MUST_NOT_BE => "option1"} }
      it { expect(subject.must_not_be).to eq(["option1"]) }
    end

    context "passed multiple must_not_bes" do
      let(:config_options) { {described_class::Keys::Options::MUST_NOT_BE => "option1,option2"} }
      it { expect(subject.must_not_be).to eq(["option1", "option2"]) }
    end
  end

  describe "#debug?" do
    subject { described_class.new options: config_options }

    context "by default" do
      let(:config_options) { Hash.new }
      it { expect(subject.debug?).to be_falsey }
    end

    context "when set" do
      let(:config_options) { {described_class::Keys::Options::DEBUG => true} }
      it { expect(subject.debug?).to be_truthy }
    end
  end

  describe "#event_visibility" do
    subject { described_class.new options: config_options }

    context "by default" do
      let(:config_options) { Hash.new }
      it { expect(subject.event_visibility).to eq(CalendarAssistant::Event::Visibility::DEFAULT) }
    end

    context "when public" do
      let(:config_options) { {described_class::Keys::Settings::VISIBILITY => CalendarAssistant::Event::Visibility::PUBLIC }  }
      it { expect(subject.event_visibility).to eq(CalendarAssistant::Event::Visibility::PUBLIC) }
    end

    context "when private" do
      let(:config_options) { {described_class::Keys::Settings::VISIBILITY => CalendarAssistant::Event::Visibility::PRIVATE }  }
      it { expect(subject.event_visibility).to eq(CalendarAssistant::Event::Visibility::PRIVATE) }
    end

    context "when explicitly default" do
      let(:config_options) { {described_class::Keys::Settings::VISIBILITY => CalendarAssistant::Event::Visibility::DEFAULT }  }
      it { expect(subject.event_visibility).to eq(CalendarAssistant::Event::Visibility::DEFAULT) }
    end

    context "when it's utter nonsense" do
      let(:config_options) { {described_class::Keys::Settings::VISIBILITY => "cloudy" }  }
      it { expect(subject.event_visibility).to eq(CalendarAssistant::Event::Visibility::DEFAULT) }
    end
  end
end
