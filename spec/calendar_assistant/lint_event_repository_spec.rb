describe CalendarAssistant::LintEventRepository do
  def expect_event_equalish e1, e2
    expect(e1.summary).to eq(e2.summary)
    expect(e1.start_time).to eq(e2.start_time)
    expect(e1.end_time).to eq(e2.end_time)
  end

  let(:service) { CalendarAssistant::LocalService.new }

  let(:lint_event_repository) { described_class.new(service, calendar_id) }
  let(:calendar_id) { CalendarAssistant::Config::DEFAULT_CALENDAR_ID }
  let(:calendar) { GCal::Calendar.new(id: calendar_id) }
  let(:event_array) { [] }

  before do
    service.insert_calendar(calendar)

    event_array.each do |event|
      service.insert_event(calendar_id, event)
    end
  end

  describe "#find" do
    freeze_time

    let(:needs_action) { event_factory(start: "today", options: :needs_action) }
    let(:other_event) { event_factory(start: "today", option: :accepted) }
    let(:event_array) { [needs_action, other_event] }

    it "filters out non-lint events" do
      time = Time.now.beginning_of_day..(Time.now + 1.day).end_of_day
      result = lint_event_repository.find(time)
      expect(result.events.count).to eq 1
      expect_event_equalish(result.events.first, needs_action)
    end

    context "when passed some predicates" do
      let(:needs_action_recurring) { event_factory(start: "today", options: [:needs_action, :recurring]) }
      let(:event_array) { [needs_action, other_event, needs_action_recurring] }

      it "filters out non-lint events and applies other predicates" do
        time = Time.now.beginning_of_day..(Time.now + 1.day).end_of_day
        result = lint_event_repository.find(time, predicates: { recurring?: false} )
        expect(result.events.count).to eq 1
        expect_event_equalish(result.events.first, needs_action)
      end
      context "and one of those precicates is asking for needs_action to be false" do
        it "still filters out non-lint events and applies other predicates" do
          time = Time.now.beginning_of_day..(Time.now + 1.day).end_of_day
          result = lint_event_repository.find(time, predicates: { needs_action?: false, recurring?: false} )
          expect(result.events.count).to eq 1
          expect_event_equalish(result.events.first, needs_action)
        end
      end
    end
  end
end
