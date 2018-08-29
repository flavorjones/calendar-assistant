describe CalendarAssistant do
  describe "geographic events" do
    let(:ca) { CalendarAssistant.new("foo@example") }
    let(:calendar) { instance_double("Google::Calendar") }
    let(:calendar_event) { instance_double("Google::Event") }

    describe "#create_event" do
      before do
        allow(ca).to receive(:calendar).and_return(calendar)
        expect(calendar).to receive(:create_event).and_yield(calendar_event)
      end

      context "called with a Time" do
        let(:event_title) { "Palo Alto" }
        let(:event_time) { Chronic.parse("tomorrow") }

        it "creates an appropriately-titled all-day event" do
          expect(calendar_event).to receive(:title=).with("#{CalendarAssistant::EMOJI_WORLDMAP}  #{event_title}")
          expect(calendar_event).to receive(:all_day=).with(event_time)

          ca.create_geographic_event(event_time, event_title)
        end

        context "when there's a pre-existing geographic event" do
          context "that lasts a single day" do
            it "removes the pre-existing event"
          end

          context "that lasts multiple days" do
            context "when the new event overlaps the start of the pre-existing event" do
              it "shrinks the pre-existing event"
            end

            context "when the new event overlaps the end of the pre-existing event" do
              it "shrinks the pre-existing event"
            end

            context "when the new event is in the middle of the pre-existing event" do
              it "splits the pre-existing event"
            end
          end
        end
      end

      context "called with a Range of Times" do
        let(:event_title) { "Palo Alto" }
        let(:event_start_time) { Chronic.parse("tomorrow") }
        let(:event_end_time) { Chronic.parse("one week from now") }

        it "creates an appropriately-titled multi-day event" do
          expect(calendar_event).to receive(:title=).with("#{CalendarAssistant::EMOJI_WORLDMAP}  #{event_title}")
          expect(calendar_event).to receive(:all_day=).with(event_start_time)
          expect(calendar_event).to receive(:end_time=).with((event_end_time + 1.day).beginning_of_day)

          ca.create_geographic_event(event_start_time..event_end_time, event_title)
        end

        context "when there's a pre-existing geographic event" do
          context "that lasts a single day" do
            it "removes the pre-existing event"
          end

          context "that lasts multiple days" do
            context "when the new event overlaps the start of the pre-existing event" do
              it "shrinks the pre-existing event"
            end

            context "when the new event overlaps the end of the pre-existing event" do
              it "shrinks the pre-existing event"
            end

            context "when the new event is in the middle of the pre-existing event" do
              it "splits the pre-existing event"
            end
          end
        end
      end
      
    end
  end
end
