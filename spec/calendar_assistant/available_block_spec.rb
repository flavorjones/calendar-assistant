require "date"

describe CalendarAssistant::AvailableBlock do
  it_behaves_like "an object that has duration" do
    let(:an_object) { described_class.new(**params) }
  end
end
