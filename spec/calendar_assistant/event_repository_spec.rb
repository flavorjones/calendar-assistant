require 'date'

describe CalendarAssistant::EventRepository do

  let(:service) { FakeService.new }

  before do
    event_array.each do |event|
      service.insert_event(calendar_id, event)
    end
  end

  it_behaves_like "an event repository" do
    let(:event_repository) {described_class.new(service, calendar_id)}
  end

end
