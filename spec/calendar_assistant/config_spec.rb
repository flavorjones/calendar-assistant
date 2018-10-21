describe CalendarAssistant::Config do
  describe ".new" do
    context "passed a config file" do
      context "TOML config file exists" do
        with_temp_config_file do
          <<~EOC
            [settings]
            start-of-day = "8am"
            end-of-day = "5:30pm"
          EOC
        end

        it "reads the TOML and makes it available as #user_config" do
          expect(described_class.new(config_file_path: temp_config_file.path).user_config).
            to eq({"settings" => {"start-of-day" => "8am", "end-of-day" => "5:30pm"}})
        end
      end

      context "config file exists but is not TOML" do
        with_temp_config_file do
          <<~EOC
            # this is yaml
            ---
            foo: 123
          EOC
        end

        it "raises an exception" do
          expect { described_class.new(config_file_path: temp_config_file.path) }.
            to raise_exception(CalendarAssistant::BaseException)
        end
      end

      context "config file does not exist" do
        it "initializes #user_config to an empty hash" do
          expect(described_class.new(config_file_path: "/path/to/nonexistent/file").user_config).
            to eq({})
        end
      end
    end

    context "passed an IO object" do
      it "reads the TOML and makes it available as #user_config" do
        expect(described_class.new(config_io: StringIO.new("foo = 123")).user_config).
          to eq("foo" => 123)
      end

      context "and is not TOML" do
        it "raises an exception" do
          expect { described_class.new(config_io: StringIO.new("foo: 123")) }.
            to raise_exception(CalendarAssistant::BaseException)
        end
      end
    end
  end

  describe "#profile_name" do
    let(:options) { Hash.new }
    subject { described_class.new(options: options, config_file_path: temp_config_file.path) }

    context "a default profile name is not configured" do
      context "no tokens exist" do
        with_temp_config_file

        it "raises an exception telling the user to authorize first" do
          expect { subject.profile_name }.to raise_exception(CalendarAssistant::BaseException)
        end
      end

      context "a token exists" do
        with_temp_config_file do
          <<~EOC
            [tokens]
            work = "fake-token-1"
            play = "fake-token-2"
          EOC
        end

        it "returns the first token key" do
          expect(subject.profile_name).to eq("work")
        end

        it "saves a default the first token key as the default profile in 'settings.profile'" do
          subject.profile_name

          new_config = CalendarAssistant::Config.new(config_file_path: temp_config_file.path)
          expect(new_config.get([CalendarAssistant::Config::Keys::SETTINGS, CalendarAssistant::Config::Keys::Settings::PROFILE])).to eq("work")
        end
      end
    end

    context "a default profile name is configured" do
      with_temp_config_file do
        <<~EOC
          [tokens]
          work = "fake-token-1"
          play = "fake-token-2"

          [settings]
          profile = "other"
        EOC
      end

      it "returns the configured default profile name" do
        expect(subject.profile_name).to eq("other")
      end

      context "a profile is specified via options" do
        let(:options) { {"profile" => "home" } }

        it "returns the profile specified in the options" do
          expect(subject.profile_name).to eq("home")
        end
      end
    end
  end

  describe "#get" do
    let(:config) do
      <<~EOC
        size = "medium"

        [things]
        thing1 = "foo"
        thing2 = "bar"
      EOC
    end

    subject { described_class.new(config_io: StringIO.new(config)) }

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
            to raise_exception(CalendarAssistant::Config::AccessingHashAsScalar)
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
    let(:config) do
      <<~EOC
        size = "medium"

        [things]
        thing1 = "foo"
        thing2 = "bar"
      EOC
    end

    subject { described_class.new(config_io: StringIO.new(config)) }

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

  describe "#persist!" do
    with_temp_config_file do
      <<~EOC
        [settings]
        start-of-day = "8am"
        end-of-day = "5:30pm"
      EOC
    end

    subject { described_class.new(config_file_path: temp_config_file.path) }

    it "persists the config to file" do
      subject.set "settings.size", "medium"
      subject.persist!
      new_config = described_class.new(config_file_path: temp_config_file.path)
      expect(new_config.get("settings.size")).to eq("medium")
    end
  end

  describe "#tokens" do
    context "there are tokens configured in user_config" do
      let(:config) do
        <<~EOC
          [tokens]
          work = "asdfasdf"
        EOC
      end

      subject { described_class.new(config_io: StringIO.new(config)) }

      it "returns the tokens hash" do
        expect(subject.tokens).to eq("work" => "asdfasdf")
      end
    end

    context "there are no tokens configured in user_config" do
      let(:config) do
        <<~EOC
          [things]
          thing1 = "asdfasdf"
        EOC
      end

      subject { described_class.new(config_io: StringIO.new(config)) }

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
end
