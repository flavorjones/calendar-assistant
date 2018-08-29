describe CalendarAssistant::CLI do
  around do |example|
    Timecop.freeze(Time.local(2018, 7, 13, 12, 1, 1)) do
      example.run
    end
  end

  describe "declare my geographic location for a day" do
    it "creates an all-day event appropriately titled" do
      mock_ca = instance_double("CalendarAssistant")
      expect(CalendarAssistant).to receive(:new).with("foo@example").and_return(mock_ca)
      expect(mock_ca).to receive("create_geographic_event").with(Chronic.parse("tomorrow"), "Palo Alto")

      CalendarAssistant::CLI.start ["where", "foo@example", "tomorrow", "Palo Alto"]
    end

    # it "creates a multi-day all-day event appropriately titled" do
    #   expect(cal_event).to receive(:title=).with("#{CalendarAssistant::EMOJI_WORLDMAP} Palo Alto")
    #   expect(cal_event).to receive(:all_day=).with(Chronic.parse("tomorrow"))
    #   expect(cal_event).to receive(:end_time=).with((Chronic.parse("three days from now") + 1.day).beginning_of_day)

    #   CalendarAssistant::CLI.start ["where", "foo@example", "tomorrow ... three days from now", "Palo Alto"]
    # end
  end

  describe "declare my geographic location for multiple days" do
  end
end
