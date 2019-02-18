require "toml"

describe CalendarAssistant::CLI::Config do
  with_temp_config_file

  let(:args) { { config_file_path: temp_config_file.path } }

  before(:each) do
    File.open(temp_config_file.path, "w") { |f| f.write(TOML::Generator.new(user_config).body) }
  end

  it_behaves_like "a configuration class"
end
