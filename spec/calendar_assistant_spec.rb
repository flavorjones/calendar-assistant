describe CalendarAssistant do
  GCal = Google::Apis::CalendarV3

  describe "event visitors" do
    it "tests event_date_description"
    it "tests event_description"
    it "tests event_attributes"
  end

  describe "events" do
    let(:service) { instance_double("CalendarService") }
    let(:calendar) { instance_double("Calendar") }
    let(:ca) { CalendarAssistant.new "profilename" }
    let(:event_array) { [instance_double("Event"), instance_double("Event")] }
    let(:events) { instance_double("Events", :items => event_array ) }

    before do
      expect(CalendarAssistant::Authorizer).to receive(:service).and_return(service)
      expect(service).to receive(:get_calendar).and_return(calendar)
    end

    describe "#find_events" do
      it "sets some basic query options" do
        expect(service).to receive(:list_events).with(CalendarAssistant::DEFAULT_CALENDAR_ID,
                                                      hash_including(order_by: "startTime",
                                                                     single_events: true,
                                                                     max_results: anything)).
                             and_return(events)
        result = ca.find_events Time.now
        expect(result).to eq(event_array)
      end

      context "given a time" do
        it "calls CalendarService#list_events with appropriate range" do
          time = Time.now
          expect(service).to receive(:list_events).with(CalendarAssistant::DEFAULT_CALENDAR_ID,
                                                        hash_including(time_min: time.beginning_of_day.iso8601,
                                                                       time_max: time.end_of_day.iso8601)).
                               and_return(events)
          result = ca.find_events time
          expect(result).to eq(event_array)
        end
      end

      context "given a time range" do
        it "calls CalendarService#list_events with appropriate range" do
          time = Time.now..(Time.now + 1.day)
          expect(service).to receive(:list_events).with(CalendarAssistant::DEFAULT_CALENDAR_ID,
                                                        hash_including(time_min: time.first.iso8601,
                                                                       time_max: time.last.iso8601)).
                               and_return(events)
          result = ca.find_events time
          expect(result).to eq(event_array)
        end
      end

      context "when no items are found" do
        let(:events) { instance_double("Events", :items => nil) }

        it "returns an empty array" do
          expect(service).to receive(:list_events).and_return(events)
          result = ca.find_events Time.now
          expect(result).to eq([])
        end
      end
    end

    describe "#find_location_events" do
      let(:location_event) { instance_double("Event", :location_event? => true) }
      let(:other_event) { instance_double("Event", :location_event? => false) }
      let(:events) { [location_event, other_event].shuffle }

      it "selects location events from results of #find_events" do
        time = Time.now

        expect(ca).to receive(:find_events).with(time).and_return(events)

        result = ca.find_location_events time
        expect(result).to eq([location_event])
      end
    end

    describe "#create_location_event" do
      let(:new_event) { instance_double("GCal::Event") }

      context "called with a date" do
        it "creates an appropriately-titled all-day event" do
          expect(GCal::Event).to(receive(:new).
                                   with(start: event_date_time(date: Date.today),
                                        end: event_date_time(date: Date.today),
                                        summary: "#{CalendarAssistant::EMOJI_WORLDMAP}  WFH").
                                   and_return(new_event))
          expect(service).to receive(:insert_event).with(CalendarAssistant::DEFAULT_CALENDAR_ID, new_event)

          ca.create_location_event Time.now, "WFH"
        end
      end
    end
  end

  xdescribe "location events" do
    let(:ca) { CalendarAssistant.new("foo@example") }
    let(:calendar) { instance_double("Google::Calendar") }
    let(:new_event) { instance_double("Google::Event") }

    before { allow(ca).to receive(:calendar).and_return(calendar) }

    describe "#create_location_event" do
      before do
        expect(calendar).to receive(:create_event).
                              and_yield(new_event).
                              and_return(new_event)
      end

      context "called with a Time" do
        let(:event_title) { "Palo Alto" }
        let(:event_time) { Chronic.parse("tomorrow") }

        it "creates an appropriately-titled all-day event" do
          expect(new_event).to receive(:title=).with("#{CalendarAssistant::EMOJI_WORLDMAP}  #{event_title}")
          expect(new_event).to receive(:all_day=).with(event_time)
          allow(ca).to receive(:find_location_events).and_return([])

          ca.create_location_event(event_time, event_title)
        end

        context "when there's a pre-existing location event" do
          let(:existing_event) { instance_double("Google::Event") }

          before do
            expect(ca).to receive(:find_location_events).and_return([existing_event])
            allow(new_event).to receive(:title=)
            allow(new_event).to receive(:all_day=)
            allow(new_event).to receive(:start_time).and_return(event_time.beginning_of_day)
            allow(new_event).to receive(:end_time).and_return((event_time + 1.day).beginning_of_day)

            # strings formatted like "2018-09-28T04:00:00Z" because of wonky Google::Event behavior
            allow(existing_event).to receive(:start_time).and_return(existing_start.utc.xmlschema)
            allow(existing_event).to receive(:end_time).and_return(existing_end.utc.xmlschema)
          end

          context "that lasts a single day" do
            let(:existing_start) { event_time.beginning_of_day }
            let(:existing_end) { (event_time + 1.day).beginning_of_day }

            it "removes the pre-existing event" do
              expect(calendar).to receive(:delete_event).with(existing_event)

              ret = ca.create_location_event(event_time, event_title)

              expect(ret).to eq({
                                  created: [new_event],
                                  deleted: [existing_event]
                                })
            end
          end

          context "that lasts multiple days" do
            context "when the new event overlaps the start of the pre-existing event" do
              let(:existing_start) { event_time.beginning_of_day }
              let(:existing_end) { (event_time + 5.days).beginning_of_day }

              it "shrinks the pre-existing event" do
                expect(calendar).to receive(:save_event).with(existing_event)
                expect(existing_event).to receive(:start_time=).with(event_time.beginning_of_day + 1.day)
                expect(existing_event).to receive(:end_time=).with(existing_end)

                ret = ca.create_location_event(event_time, event_title)

                expect(ret).to eq({
                                    created: [new_event],
                                    modified: [existing_event]
                                  })
              end
            end

            context "when the new event overlaps the end of the pre-existing event" do
              let(:existing_start) { (event_time - 5.days).beginning_of_day }
              let(:existing_end) { (event_time + 1.day).beginning_of_day }

              it "shrinks the pre-existing event" do
                expect(calendar).to receive(:save_event).with(existing_event)
                expect(existing_event).to receive(:end_time=).with(event_time.beginning_of_day)

                ret = ca.create_location_event(event_time, event_title)

                expect(ret).to eq({
                                    created: [new_event],
                                    modified: [existing_event]
                                  })
              end
            end

            context "when the new event is in the middle of the pre-existing event" do
              let(:existing_start) { (event_time - 5.days).beginning_of_day }
              let(:existing_end) { (event_time + 5.days).beginning_of_day }

              it "shrinks the pre-existing event" do
                expect(calendar).to receive(:save_event).with(existing_event)
                expect(existing_event).to receive(:end_time=).with(event_time.beginning_of_day)

                ret = ca.create_location_event(event_time, event_title)

                expect(ret).to eq({
                                    created: [new_event],
                                    modified: [existing_event]
                                  })
              end
            end
          end
        end
      end

      context "called with a Range of Times" do
        let(:event_title) { "Palo Alto" }
        let(:event_start_time) { Chronic.parse("tomorrow") }
        let(:event_end_time) { event_start_time + 7.days }

        it "creates an appropriately-titled multi-day event" do
          expect(new_event).to receive(:title=).with("#{CalendarAssistant::EMOJI_WORLDMAP}  #{event_title}")
          expect(new_event).to receive(:all_day=).with(event_start_time)
          expect(new_event).to receive(:end_time=).with((event_end_time + 1.day).beginning_of_day)

          allow(ca).to receive(:find_location_events).and_return([])

          ca.create_location_event(event_start_time..event_end_time, event_title)
        end

        context "when there's a pre-existing location event" do
          let(:existing_event) { instance_double("Google::Event") }

          before do
            expect(ca).to receive(:find_location_events).and_return([existing_event])
            allow(new_event).to receive(:title=)
            allow(new_event).to receive(:all_day=)
            allow(new_event).to receive(:end_time=).with((event_end_time + 1.day).beginning_of_day)
            allow(new_event).to receive(:start_time).and_return(event_start_time.beginning_of_day)
            allow(new_event).to receive(:end_time).and_return((event_end_time + 1.day).beginning_of_day)

            # strings formatted like "2018-09-28T04:00:00Z" because of wonky Google::Event behavior
            allow(existing_event).to receive(:start_time).and_return(existing_start.utc.xmlschema)
            allow(existing_event).to receive(:end_time).and_return(existing_end.utc.xmlschema)
          end

          context "that lasts a single day" do
            let(:existing_start) { (event_start_time + 2.days).beginning_of_day }
            let(:existing_end) { (existing_start + 1.day).beginning_of_day }

            it "removes the pre-existing event" do
              expect(calendar).to receive(:delete_event).with(existing_event)

              ret = ca.create_location_event(event_start_time..event_end_time, event_title)

              expect(ret).to eq({
                                  created: [new_event],
                                  deleted: [existing_event]
                                })
            end
          end

          context "that lasts multiple days" do
            context "when the new event entirely overlaps the pre-existing event" do
              let(:existing_start) { (event_start_time + 1.day).beginning_of_day }
              let(:existing_end) { (event_end_time - 1.day).beginning_of_day }

              it "removes the pre-existing event" do
                expect(calendar).to receive(:delete_event).with(existing_event)

                ret = ca.create_location_event(event_start_time..event_end_time, event_title)

                expect(ret).to eq({
                                    created: [new_event],
                                    deleted: [existing_event]
                                  })
              end
            end

            context "when the new event overlaps the start of the pre-existing event" do
              let(:existing_start) { (event_end_time - 2.days).beginning_of_day }
              let(:existing_end) { (event_end_time + 2.days).beginning_of_day }

              it "shrinks the pre-existing event" do
                expect(calendar).to receive(:save_event).with(existing_event)
                expect(existing_event).to receive(:start_time=).with(event_end_time.beginning_of_day + 1.day)
                expect(existing_event).to receive(:end_time=).with(existing_end)

                ret = ca.create_location_event(event_start_time..event_end_time, event_title)

                expect(ret).to eq({
                                    created: [new_event],
                                    modified: [existing_event]
                                  })
              end
            end

            context "when the new event overlaps the end of the pre-existing event" do
              let(:existing_start) { (event_start_time - 2.days).beginning_of_day }
              let(:existing_end) { (event_start_time + 2.days).beginning_of_day }

              it "shrinks the pre-existing event" do
                expect(calendar).to receive(:save_event).with(existing_event)
                expect(existing_event).to receive(:end_time=).with(event_start_time.beginning_of_day)

                ret = ca.create_location_event(event_start_time..event_end_time, event_title)

                expect(ret).to eq({
                                    created: [new_event],
                                    modified: [existing_event]
                                  })
              end
            end

            context "when the new event is in the middle of the pre-existing event" do
              let(:existing_start) { (event_start_time - 2.days).beginning_of_day }
              let(:existing_end) { (event_end_time + 2.days).beginning_of_day }

              it "shrinks the pre-existing event" do
                expect(calendar).to receive(:save_event).with(existing_event)
                expect(existing_event).to receive(:end_time=).with(event_start_time.beginning_of_day)

                ret = ca.create_location_event(event_start_time..event_end_time, event_title)

                expect(ret).to eq({
                                    created: [new_event],
                                    modified: [existing_event]
                                  })
              end
            end
          end
        end
      end
    end
  end
end
