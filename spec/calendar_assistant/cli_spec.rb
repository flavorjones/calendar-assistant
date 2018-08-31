describe CalendarAssistant::CLI do
  around do |example|
    Timecop.freeze(Time.local(2018, 7, 13, 12, 1, 1)) do
      example.run
    end
  end

  let(:mock_ca) { instance_double("CalendarAssistant") }
  let(:calendar_id) { "foo@example" }

  before do
    expect(CalendarAssistant).to receive(:new).with(calendar_id).and_return(mock_ca)
  end

  describe "get" do
    let(:mock_events) { [instance_double("Google::Event"), instance_double("Google::Event")] }

    context "for a date" do
      it "calls find_events with the right arguments" do
        expect(mock_ca).to receive("find_events").
                             with(Chronic.parse("tomorrow")).
                             and_return(mock_events)
        mock_events.each { |mock_event| expect(mock_event).to receive(:to_assistant_s) }

        CalendarAssistant::CLI.start ["get", calendar_id, "tomorrow"]
      end
    end

    context "for a date range" do
      it "calls find_events with the right arguments" do
        expect(mock_ca).to receive("find_events").
                             with(Chronic.parse("tomorrow")..Chronic.parse("one week from now")).
                             and_return(mock_events)
        mock_events.each { |mock_event| expect(mock_event).to receive(:to_assistant_s) }

        CalendarAssistant::CLI.start ["get", calendar_id, "tomorrow...one week from now"]
      end
    end
  end

  describe "location" do
    describe "set" do
      context "for a date" do
        it "calls create_location_event with the right arguments" do
          expect(mock_ca).to receive("create_location_event").
                               with(Chronic.parse("tomorrow"), "Palo Alto").
                               and_return({})

          CalendarAssistant::CLI.start ["location", "set", calendar_id, "tomorrow", "Palo Alto"]
        end
      end

      context "for a date range with spaces" do
        it "calls create_location_event with the right arguments" do
          expect(mock_ca).to receive("create_location_event").
                               with(Chronic.parse("tomorrow")..(Chronic.parse("three days from now") + 1.day).beginning_of_day,
                                    "Palo Alto").
                               and_return({})

          CalendarAssistant::CLI.start ["location", "set", calendar_id, "tomorrow ... three days from now", "Palo Alto"]
        end
      end

      context "for a date range without spaces" do
        it "calls create_location_event with the right arguments" do
          expect(mock_ca).to receive("create_location_event").
                               with(Chronic.parse("tomorrow")..(Chronic.parse("three days from now") + 1.day).beginning_of_day,
                                    "Palo Alto").
                               and_return({})

          CalendarAssistant::CLI.start ["location", "set", calendar_id, "tomorrow...three days from now", "Palo Alto"]
        end
      end
    end

    describe "get" do
      let(:mock_events) { [instance_double("Google::Event"), instance_double("Google::Event")] }

      context "for a date" do
        it "calls find_location_events with the right arguments" do
          expect(mock_ca).to receive("find_location_events").
                               with(Chronic.parse("tomorrow")).
                               and_return(mock_events)
          mock_events.each { |mock_event| expect(mock_event).to receive(:to_assistant_s) }

          CalendarAssistant::CLI.start ["location", "get", calendar_id, "tomorrow"]
        end
      end

      context "for a date range" do
        it "calls find_location_events with the right arguments" do
          expect(mock_ca).to receive("find_location_events").
                               with(Chronic.parse("tomorrow")..Chronic.parse("one week from now")).
                               and_return(mock_events)
          mock_events.each { |mock_event| expect(mock_event).to receive(:to_assistant_s) }

          CalendarAssistant::CLI.start ["location", "get", calendar_id, "tomorrow...one week from now"]
        end
      end
    end
  end
end
