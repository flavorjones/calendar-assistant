describe CalendarAssistant::Config::TokenStore do
  describe "#load" do
    context "with a user config" do
      subject { CalendarAssistant::Config.new(config_io: config_io).token_store }

      let :config_io do
        StringIO.new <<~EOC
            [tokens]
            work = "fake-token-string"
          EOC
      end

      context "loading an existing token" do
        it "loads a token from under the 'tokens' key in the config file" do
          expect(subject.load("work")).to eq("fake-token-string")
        end
      end

      context "loading a non-existent token" do
        it "returns nil" do
          expect(subject.load("play")).to be_nil
        end
      end
    end

    context "without a user config" do
      subject { CalendarAssistant::Config.new(config_file_path: "/path/to/no/file").token_store }

      it "returns nil" do
        expect(subject.load("play")).to be_nil
      end
    end
  end

  describe "#store" do
    context "with config file" do
      with_temp_config_file

      subject do
        CalendarAssistant::Config.new(config_file_path: temp_config_file.path).token_store
      end

      context "with a user config" do
        it "stores the token in the file" do
          subject.store "work", "fake-token-string"
          expect(TOML.load_file(temp_config_file.path)["tokens"]["work"]).to eq("fake-token-string")
        end

        it "is read in appropriately by a new config" do
          subject.store "work", "fake-token-string"

          new_store = CalendarAssistant::Config.new(config_file_path: temp_config_file.path).token_store
          expect(new_store.load("work")).to eq("fake-token-string")
        end
      end
    end

    context "with config IO" do
      subject do
        CalendarAssistant::Config.new(config_io: StringIO.new("foo = 123")).token_store
      end

      it "raises an exception" do
        expect { subject.store "work", "fake-token-string" }.
          to raise_exception(CalendarAssistant::Config::NoConfigFileToPersist)
      end
    end
  end

  describe "#delete" do
    with_temp_config_file do
      <<~EOC
          [tokens]
          work = "fake-token-string"
          play = "fake-token-string2"
        EOC
    end

    subject do
      CalendarAssistant::Config.new(config_file_path: temp_config_file.path).token_store
    end

    it "is setup correctly" do
      expect(subject.load("work")).to eq("fake-token-string")
    end

    context "when deleting an existing token" do
      it "removes the token from file" do
        subject.delete "work"
        expect(TOML.load_file(temp_config_file.path)["tokens"]["work"]).to be_nil
      end

      it "removes the token for a new config" do
        subject.delete "work"

        new_store = CalendarAssistant::Config.new(config_file_path: temp_config_file.path).token_store
        expect(new_store.load("work")).to be_nil
      end
    end

    context "when deleting a non-existent token" do
      it "does nothing" do
        subject.delete "nonexistent-profile-name"
        new_store = CalendarAssistant::Config.new(config_file_path: temp_config_file.path).token_store

        expect(subject.config.user_config).to eq(new_store.config.user_config)
      end
    end
  end
end
