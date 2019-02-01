describe CalendarAssistant::LocationEventRepository do
  def expect_event_equalish e1, e2
    expect(e1.summary).to eq(e2.summary)
    expect(e1.start_time).to eq(e2.start_time)
    expect(e1.end_time).to eq(e2.end_time)
  end

  let(:service) { CalendarAssistant::LocalService.new }

  let(:location_event_repository) { described_class.new(service, calendar_id) }
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

    let(:location_event) { event_factory(start: "today", options: :location_event) }
    let(:other_event) { event_factory(start: "today") }

    let(:event_array) { [location_event, other_event] }
    let(:event_set) { CalendarAssistant::EventSet.new event_repository, event_array }


    it "filters out non-location events" do
      time = Time.now.beginning_of_day..(Time.now + 1.day).end_of_day
      result = location_event_repository.find(time)
      expect_event_equalish(result.events.first, location_event)
    end
  end

  describe "#create_location_event" do
    freeze_time

    let(:new_event) { event_factory(start: new_event_start_date, end: new_event_end_date, summary: "New Zealand", options: :location_event) }
    let(:event_set) { location_event_repository.create(userspec, "New Zealand") }
    let(:created_event) { event_set.events[:created].first }
    let(:deleted_event) { event_set.events[:deleted].first }
    let(:modified_event) { event_set.events[:modified].first }

    context "called with a Date" do
      let(:userspec) { CalendarAssistant::CLI::Helpers.parse_datespec("today") }

      let(:new_event_start_date) { Date.today }
      let(:new_event_end_date) { new_event_start_date }

      it "creates an appropriately-titled transparent all-day event" do
        expect_event_equalish(created_event, new_event)
      end
    end

    context "called with a Date Range" do
      let(:userspec) { new_event_start_date..new_event_end_date }

      let(:new_event_start_date) { Date.parse("2019-09-03") }
      let(:new_event_end_date) { Date.parse("2019-09-05") }

      it "creates an appropriately-titled transparent all-day event" do
        expect_event_equalish(created_event, new_event)
      end
    end

    context "when there's a pre-existing location event" do
      let(:existing_event) { event_factory(start: existing_event_start_date, end: existing_event_end_date, summary: "Camelot", options: :location_event) }
      let(:event_array) { [existing_event] }

      let(:new_event_start_date) { Date.parse("2019-09-03") }
      let(:new_event_end_date) { Date.parse("2019-09-05") }

      let(:userspec) { new_event_start_date..new_event_end_date }

      context "when the new event is entirely within the range of the pre-existing event" do
        let(:existing_event_start_date) { new_event_start_date }
        let(:existing_event_end_date) { new_event_end_date }

        it "removes the pre-existing event" do
          expect(location_event_repository.find(userspec).events).to include(existing_event)

          expect_event_equalish(created_event, new_event)
          expect_event_equalish(deleted_event, existing_event)

          expect(location_event_repository.find(userspec).events).to_not include(existing_event)
        end
      end

      context "when the new event overlaps the start of the pre-existing event" do
        let(:existing_event_start_date) { Date.parse("2019-09-04") }
        let(:existing_event_end_date) { Date.parse("2019-09-06") }

        it "shrinks the pre-existing event" do
          expect_event_equalish(created_event, new_event)
          expect_event_equalish(modified_event, existing_event)
          expect(location_event_repository.find(existing_event_end_date..existing_event_end_date + 1).events).to include (existing_event)
        end
      end

      context "when the new event overlaps the end of the pre-existing event" do
        let(:existing_event_start_date) { Date.parse("2019-09-02") }
        let(:existing_event_end_date) { Date.parse("2019-09-04") }

        it "shrinks the pre-existing event" do
          expect_event_equalish(created_event, new_event)
          expect_event_equalish(modified_event, existing_event)
          expect(location_event_repository.find(existing_event_start_date..new_event_start_date + 1).events).to include (existing_event)
        end
      end

      context "when the new event is completely overlapped by the pre-existing event" do
        let(:existing_event_start_date) { Date.parse("2019-09-02") }
        let(:existing_event_end_date) { Date.parse("2019-09-06") }

        it "shrinks the pre-existing event" do
          expect_event_equalish(created_event, new_event)
          expect_event_equalish(modified_event, existing_event)
          expect(location_event_repository.find(existing_event_end_date..existing_event_end_date + 1).events).to include (existing_event)
        end
      end
    end
  end
end
