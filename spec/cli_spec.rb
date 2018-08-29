describe CalendarAssistant::CLI do
  around do |example|
    Timecop.freeze(Time.local(2018, 7, 13, 12, 1, 1)) do
      example.run
    end
  end

  describe "declare my geographic location for a day" do
    let(:mock_ca) { instance_double("CalendarAssistant") }

    before do
      expect(CalendarAssistant).to receive(:new).with("foo@example").and_return(mock_ca)
    end

    it "creates an all-day event appropriately titled" do
      expect(mock_ca).to receive("create_geographic_event").with(Chronic.parse("tomorrow"), "Palo Alto")

      CalendarAssistant::CLI.start ["location", "set", "foo@example", "tomorrow", "Palo Alto"]
    end

    context "creates a multi-day all-day event appropriately titled" do
      it "with spaces" do
        expect(mock_ca).to receive("create_geographic_event").with(Chronic.parse("tomorrow")..(Chronic.parse("three days from now") + 1.day).beginning_of_day, "Palo Alto")

        CalendarAssistant::CLI.start ["location", "set", "foo@example", "tomorrow ... three days from now", "Palo Alto"]
      end

      it "without spaces" do
        expect(mock_ca).to receive("create_geographic_event").with(Chronic.parse("tomorrow")..(Chronic.parse("three days from now") + 1.day).beginning_of_day, "Palo Alto")

        CalendarAssistant::CLI.start ["location", "set", "foo@example", "tomorrow...three days from now", "Palo Alto"]
      end
    end
  end
end
