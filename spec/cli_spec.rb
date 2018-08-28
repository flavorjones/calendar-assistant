
describe CalendarAssistant::CLI do
  let(:cal) { instance_double("Google::Calendar") }
  let(:cal_event) { instance_double("Google::Event") }

  before do
    allow(CalendarAssistant).to receive(:calendar_for).and_return(cal)
    expect(cal).to receive(:create_event).and_yield(cal_event)
  end

  context "on 2018-07-13" do
    around :each do |example|
      Timecop.freeze(Time.local(2018, 7, 13, 12, 0, 0)) do
        example.run
      end
    end

    describe "a declaration of my geographic location" do
      it "creates an all-day event appropriately titled" do
        expect(cal_event).to receive(:title=).with("#{CalendarAssistant::EMOJI_WORLDMAP} Palo Alto")
        expect(cal_event).to receive(:all_day=).with(Chronic.parse("tomorrow"))

        CalendarAssistant::CLI.start ["where", "-c", "foo@example", "tomorrow", "Palo Alto"]
      end

      it "creates a multi-day all-day event appropriately titled" do
        expect(cal_event).to receive(:title=).with("#{CalendarAssistant::EMOJI_WORLDMAP} Palo Alto")
        expect(cal_event).to receive(:all_day=).with(Chronic.parse("tomorrow"))
        expect(cal_event).to receive(:end_time=).with((Chronic.parse("three days from now") + 1.day).beginning_of_day)

        CalendarAssistant::CLI.start ["where", "-c", "foo@example", "tomorrow ... three days from now", "Palo Alto"]
      end

      it "clears the current one before creating a new one"
    end
  end
end
