describe CalendarAssistant::LocationConfigValidator do
  let(:config) { CalendarAssistant::Config.new(options: config_options) }
  let(:config_options) { { } }

  describe ".valid?" do
    context "when there are no other calendar ids" do

      it "does not raise an error" do
        expect { described_class.valid?(config) }.to_not raise_error
      end
    end

    context "when there are other calendar ids" do
      context "and nickname is set" do
        let(:config_options) do
          {
              CalendarAssistant::Config::Keys::Options::CALENDARS => "two@example.com",
              CalendarAssistant::Config::Keys::Settings::NICKNAME => "steve"
          }
        end

        it "does not raise an error" do
          expect { described_class.valid?(config) }.to_not raise_error
        end
      end

      context "when nickname is not set" do
        let(:config_options) do
          {
              CalendarAssistant::Config::Keys::Options::CALENDARS => "two@example.com"
          }
        end

        it "does raise an error" do
          expect { described_class.valid?(config) }.to raise_error(CalendarAssistant::BaseException)
        end
      end

      context "when nickname is not set but force is true" do
        let(:config_options) do
          {
              CalendarAssistant::Config::Keys::Options::CALENDARS => "two@example.com",
              CalendarAssistant::Config::Keys::Options::FORCE => "two@example.com"
          }
        end

        it "does not raise an error" do
          expect { described_class.valid?(config) }.to_not raise_error
        end
      end
    end
  end
end