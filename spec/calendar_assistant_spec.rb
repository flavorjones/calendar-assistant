describe CalendarAssistant do
  describe ".token_for" do
    it "tests .token_for"
  end
  describe ".save_token_for" do
    it "tests .save_token_for"
  end
  describe ".params_for" do
    it "tests .params_for"
  end
  describe ".calendar_for" do
    it "tests .calendar_for"
  end
  describe ".calendar_list_for" do
    it "tests .calendar_list_for"
  end


  describe "location events" do
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

    describe "#find_events" do
      let(:existing_event) { instance_double("Google::Event") }
      let(:existing_location_event) { instance_double("Google::Event") }
      let(:event_time) { Chronic.parse("tomorrow") }

      before do
        allow(existing_event).to receive(:assistant_location_event?) { false }
        allow(existing_location_event).to receive(:assistant_location_event?) { true }
      end

      context "passed a Time" do
        it "fetches events for that day" do
          search_start_time = event_time.beginning_of_day
          search_end_time = (event_time + 1.day).beginning_of_day

          expect(calendar).to receive(:find_events_in_range).
                                with(search_start_time, search_end_time, hash_including(max_results: anything)).
                                and_return([existing_event, existing_location_event])

          events = ca.find_events(event_time)

          expect(events).to eq([existing_event, existing_location_event])
        end
      end

      context "passed a Range of Times" do
        it "fetches events for that date range" do
          query_start = event_time - 1.day
          query_end = event_time + 1.day

          search_start_time = query_start.beginning_of_day
          search_end_time = (query_end + 1.day).beginning_of_day

          expect(calendar).to receive(:find_events_in_range).
                                with(search_start_time, search_end_time, hash_including(max_results: anything)).
                                and_return([existing_event, existing_location_event])

          events = ca.find_events(query_start..query_end)

          expect(events).to eq([existing_event, existing_location_event])
        end
      end
    end

    describe "#find_location_events" do
      let(:existing_event) { instance_double("Google::Event") }
      let(:existing_location_event) { instance_double("Google::Event") }
      let(:event_time) { Chronic.parse("tomorrow") }

      before do
        allow(existing_event).to receive(:assistant_location_event?) { false }
        allow(existing_location_event).to receive(:assistant_location_event?) { true }
      end

      context "passed a Time" do
        it "fetches only location events for that day" do
          search_start_time = event_time.beginning_of_day
          search_end_time = (event_time + 1.day).beginning_of_day

          expect(calendar).to receive(:find_events_in_range).
                                with(search_start_time, search_end_time, hash_including(max_results: anything)).
                                and_return([existing_event, existing_location_event])

          events = ca.find_location_events(event_time)

          expect(events).to eq([existing_location_event])
        end
      end

      context "passed a Range of Times" do
        it "fetches events for that date range" do
          query_start = event_time - 1.day
          query_end = event_time + 1.day

          search_start_time = query_start.beginning_of_day
          search_end_time = (query_end + 1.day).beginning_of_day

          expect(calendar).to receive(:find_events_in_range).
                                with(search_start_time, search_end_time, hash_including(max_results: anything)).
                                and_return([existing_event, existing_location_event])

          events = ca.find_location_events(query_start..query_end)

          expect(events).to eq([existing_location_event])
        end
      end
    end
  end
end
