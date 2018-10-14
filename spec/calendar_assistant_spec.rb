describe CalendarAssistant do
  describe "class methods" do
    describe ".date_range_cast" do
      context "given a Range of Times" do
        let(:start_time) { Chronic.parse "72 hours ago" }
        let(:end_time) { Chronic.parse "30 hours from now" }

        it "returns a Date range with the end date augmented for an all-day-event" do
          result = CalendarAssistant.date_range_cast(start_time..end_time)
          expect(result).to eq(start_time.to_date..(end_time.to_date + 1))
        end
      end
    end

    describe ".authorize" do
      let(:authorizer) { instance_double("Authorizer") }

      it "calls through to the Authorize class" do
        expect(CalendarAssistant::Authorizer).to(
          receive(:new).
            with("profile", instance_of(CalendarAssistant::Config::TokenStore)).
            and_return(authorizer)
        )
        expect(authorizer).to receive(:authorize)
        CalendarAssistant.authorize("profile")
      end
    end
  end

  describe "events" do
    let(:service) { instance_double("CalendarService") }
    let(:calendar) { instance_double("Calendar") }
    let(:ca) { CalendarAssistant.new "profilename" }
    let(:event_array) { [instance_double("Event"), instance_double("Event")] }
    let(:events) { instance_double("Events", :items => event_array ) }
    let(:authorizer) { instance_double("Authorizer") }

    before do
      allow(CalendarAssistant::Authorizer).to receive(:new).and_return(authorizer)
      allow(authorizer).to receive(:service).and_return(service)
      allow(service).to receive(:get_calendar).and_return(calendar)
    end

    describe "#find_events" do
      let(:time_range) { Time.now..(Time.now + 1.day) }

      it "sets some basic query options" do
        expect(service).to receive(:list_events).with(CalendarAssistant::DEFAULT_CALENDAR_ID,
                                                      hash_including(order_by: "startTime",
                                                                     single_events: true,
                                                                     max_results: anything)).
                             and_return(events)
        result = ca.find_events time_range
        expect(result).to eq(event_array)
      end

      context "given a time range" do
        it "calls CalendarService#list_events with the range" do
          expect(service).to receive(:list_events).with(CalendarAssistant::DEFAULT_CALENDAR_ID,
                                                        hash_including(time_min: time_range.first.iso8601,
                                                                       time_max: time_range.last.iso8601)).
                               and_return(events)
          result = ca.find_events time_range
          expect(result).to eq(event_array)
        end
      end

      context "when no items are found" do
        let(:events) { instance_double("Events", :items => nil) }

        it "returns an empty array" do
          expect(service).to receive(:list_events).and_return(events)
          result = ca.find_events time_range
          expect(result).to eq([])
        end
      end
    end

    describe "#find_location_events" do
      let(:location_event) { instance_double("Event", :location_event? => true) }
      let(:other_event) { instance_double("Event", :location_event? => false) }
      let(:events) { [location_event, other_event].shuffle }

      it "selects location events from results of #find_events" do
        time = Time.now.beginning_of_day..(Time.now + 1.day).end_of_day

        expect(ca).to receive(:find_events).with(time).and_return(events)

        result = ca.find_location_events time
        expect(result).to eq([location_event])
      end
    end

    describe "#create_location_event" do
      let(:new_event) do
        instance_double("GCal::Event", {
                          id: SecureRandom.uuid,
                          start: new_event_start,
                          end: new_event_end
                        })
      end

      before do
        allow(service).to receive(:list_events).and_return(nil)
      end

      let(:new_event_start) { GCal::EventDateTime.new date: new_event_start_date }
      let(:new_event_end) { GCal::EventDateTime.new date: (new_event_end_date + 1.day) } # always one day later than actual end

      context "called with a Date" do
        let(:new_event_start_date) { Date.today }
        let(:new_event_end_date) { new_event_start_date }

        it "creates an appropriately-titled transparent all-day event" do
          expect(GCal::Event).to(receive(:new).
                                   with(start: event_date_time(date: new_event_start.date),
                                        end: event_date_time(date: new_event_end.date),
                                        summary: "#{CalendarAssistant::EMOJI_WORLDMAP}  WFH",
                                        transparency: GCal::Event::Transparency::TRANSPARENT).
                                   and_return(new_event))
          expect(service).to receive(:insert_event).with(CalendarAssistant::DEFAULT_CALENDAR_ID, new_event).and_return(new_event)

          response = ca.create_location_event CalendarAssistant::CLIHelpers.parse_datespec("today"), "WFH"
          expect(response[:created]).to eq([new_event])
        end
      end

      context "called with a Date Range" do
        let(:new_event_start_date) { Date.parse("2019-09-03") }
        let(:new_event_end_date) { Date.parse("2019-09-05") }

        it "creates an appropriately-titled transparent all-day event" do
          expect(GCal::Event).to(receive(:new).
                                   with(start: event_date_time(date: new_event_start.date),
                                        end: event_date_time(date: new_event_end.date),
                                        summary: "#{CalendarAssistant::EMOJI_WORLDMAP}  WFH",
                                        transparency: GCal::Event::Transparency::TRANSPARENT).
                                   and_return(new_event))
          expect(service).to receive(:insert_event).with(CalendarAssistant::DEFAULT_CALENDAR_ID, new_event).and_return(new_event)

          response = ca.create_location_event new_event_start_date..new_event_end_date, "WFH"
          expect(response[:created]).to eq([new_event])
        end
      end

      context "when there's a pre-existing location event" do
        let(:existing_event_start) { GCal::EventDateTime.new date: existing_event_start_date }
        let(:existing_event_end) { GCal::EventDateTime.new date: (existing_event_end_date + 1.day) } # always one day later than actual end

        let(:new_event_start_date) { Date.parse("2019-09-03") }
        let(:new_event_end_date) { Date.parse("2019-09-05") }

        let(:existing_event) do
          instance_double("GCal::Event", {
                            id: SecureRandom.uuid,
                            start: existing_event_start,
                            end: existing_event_end
                          })
        end

        before do
          expect(GCal::Event).to(receive(:new).
                                   with(start: event_date_time(date: new_event_start.date),
                                        end: event_date_time(date: new_event_end.date),
                                        summary: "#{CalendarAssistant::EMOJI_WORLDMAP}  WFH",
                                        transparency: GCal::Event::Transparency::TRANSPARENT).
                                   and_return(new_event))
          expect(service).to receive(:insert_event).with(CalendarAssistant::DEFAULT_CALENDAR_ID, new_event).and_return(new_event)
          expect(ca).to receive(:find_location_events).and_return([existing_event])
        end

        context "when the new event is entirely within the range of the pre-existing event" do
          let(:existing_event_start_date) { new_event_start_date }
          let(:existing_event_end_date) { new_event_end_date }

          it "removes the pre-existing event" do
            expect(service).to receive(:delete_event).with(CalendarAssistant::DEFAULT_CALENDAR_ID, existing_event.id)

            response = ca.create_location_event new_event_start_date..new_event_end_date, "WFH"
            expect(response[:created]).to eq([new_event])
            expect(response[:deleted]).to eq([existing_event])
          end
        end

        context "when the new event overlaps the start of the pre-existing event" do
          let(:existing_event_start_date) { Date.parse("2019-09-04") }
          let(:existing_event_end_date) { Date.parse("2019-09-06") }

          it "shrinks the pre-existing event" do
            expect(existing_event).to receive(:update!).with(start: event_date_time(date: "2019-09-06"))
            expect(service).to receive(:update_event).with(CalendarAssistant::DEFAULT_CALENDAR_ID, existing_event.id, existing_event)

            response = ca.create_location_event new_event_start_date..new_event_end_date, "WFH"
            expect(response[:created]).to eq([new_event])
            expect(response[:modified]).to eq([existing_event])
          end
        end

        context "when the new event overlaps the end of the pre-existing event" do
          let(:existing_event_start_date) { Date.parse("2019-09-02") }
          let(:existing_event_end_date) { Date.parse("2019-09-04") }

          it "shrinks the pre-existing event" do
            expect(existing_event).to receive(:update!).with(end: event_date_time(date: "2019-09-03"))
            expect(service).to receive(:update_event).with(CalendarAssistant::DEFAULT_CALENDAR_ID, existing_event.id, existing_event)

            response = ca.create_location_event new_event_start_date..new_event_end_date, "WFH"
            expect(response[:created]).to eq([new_event])
            expect(response[:modified]).to eq([existing_event])
          end
        end

        context "when the new event is completely overlapped by the pre-existing event" do
          let(:existing_event_start_date) { Date.parse("2019-09-02") }
          let(:existing_event_end_date) { Date.parse("2019-09-06") }

          it "shrinks the pre-existing event" do
            expect(existing_event).to receive(:update!).with(start: event_date_time(date: "2019-09-06"))
            expect(service).to receive(:update_event).with(CalendarAssistant::DEFAULT_CALENDAR_ID, existing_event.id, existing_event)

            response = ca.create_location_event new_event_start_date..new_event_end_date, "WFH"
            expect(response[:created]).to eq([new_event])
            expect(response[:modified]).to eq([existing_event])
          end
        end
      end
    end
  end

  describe "event formatting" do
    describe "#event_description" do it end
    describe "#event_date_description" do it end
  end
end
