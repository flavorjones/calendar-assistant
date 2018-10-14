describe CalendarAssistant::Config do
  describe ".new" do
    context "config file exists" do
      it "reads the TOML and makes it available as #user_config" do
        expect(described_class.new(config_file_path: artifact_path("user_config_1")).user_config).
          to eq({"settings" => {"start-of-day" => "8am", "end-of-day" => "5:30pm"}})
      end
    end

    context "config file does not exist" do
      it "initializes #user_config to an empty hash" do
        expect(described_class.new(config_file_path: "/path/to/nonexistent/file").user_config).
          to eq({})
      end
    end
  end
end
