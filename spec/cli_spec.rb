
describe CalendarAssistant::CLI do
  context "on 2018-07-13" do
    around :each do |example|
      Timecop.freeze(Time.local(2018, 7, 13, 12, 0, 0)) do
        example.run
      end
    end

    describe "a declaration of my geographic location" do
      it "creates an all-day event appropriately titled" do
        cal = instance_double("Google::Calendar")
        cal_event = instance_double("Google::Event")

        allow(CalendarAssistant).to receive(:calendar_for).and_return(cal)
        expect(cal).to receive(:create_event).and_yield(cal_event)

        expect(cal_event).to receive(:title=).with("#{CalendarAssistant::EMOJI_WORLDMAP} Palo Alto")
        expect(cal_event).to receive(:all_day=).with(Chronic.parse("tomorrow"))

        CalendarAssistant::CLI.start ["where", "-c", "foo@example", "tomorrow", "Palo Alto"]
      end

      it "clears the current one before creating a new one"
    end
  end
end
