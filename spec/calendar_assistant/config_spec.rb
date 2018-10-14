describe CalendarAssistant::Config do
  describe ".new" do
    context "passed a config file" do
      context "config file exists" do
        it "reads the TOML and makes it available as #user_config" do
          expect(described_class.new(config_file_path: artifact_path("user_config_1")).user_config).
            to eq({"settings" => {"start-of-day" => "8am", "end-of-day" => "5:30pm"}})
        end

        context "and is not TOML" do
          it "raises an exception" do
            expect { described_class.new(config_file_path: artifact_path("user_config_bad")) }.
              to raise_exception(CalendarAssistant::BaseException)
          end
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
end