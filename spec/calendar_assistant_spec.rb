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

    describe ".in_tz" do
      it "sets the timezone and restores it" do
        Time.zone = "Pacific/Fiji"
        ENV['TZ'] = "Pacific/Fiji"
        CalendarAssistant.in_tz "Europe/Istanbul" do
          expect(Time.zone.name).to eq("Europe/Istanbul")
          expect(ENV['TZ']).to eq("Europe/Istanbul")
        end
        expect(Time.zone.name).to eq("Pacific/Fiji")
        expect(ENV['TZ']).to eq("Pacific/Fiji")
      end

      it "exceptionally restores the timezone" do
        Time.zone = "Pacific/Fiji"
        ENV['TZ'] = "Pacific/Fiji"
        begin
          CalendarAssistant.in_tz "Europe/Istanbul" do
            raise RuntimeError
          end
        rescue
        end
        expect(Time.zone.name).to eq("Pacific/Fiji")
        expect(ENV['TZ']).to eq("Pacific/Fiji")
      end
    end
  end

  describe "using the local file store" do
    with_temp_file("filestore", :temp_filestore_file)

    let(:ca) { CalendarAssistant.new config }
    let(:local_service) { CalendarAssistant::LocalService.new(file: filename) }
    let(:filename) { temp_filestore_file.path }
    let(:config) { CalendarAssistant::Config.new options: config_options }
    let(:config_options) { {CalendarAssistant::Config::Keys::Options::LOCAL_STORE => filename} }

    before do
      event_list_factory(file: filename, calendar_id: "primary") do
        [
            {start: "10:00", end: "11:00", options: [:recurring, :self], id: "eminently beautiful"},
            {start: "10:00", end: "11:00", options: [:recurring]},
            {start: "10:00", end: "11:00", summary: "test", options: [:recurring, :one_on_one]}
        ]
      end
    end

    it "reads from those events" do
      results = ca.find_events(Time.now.beginning_of_day..(Time.now + 1.day))
      expect(results.events.length).to eq 3
      expect(results.events.first.id).to eq "eminently beautiful"
    end
  end

  describe "events" do
    let(:service) { instance_double("CalendarService") }
    let(:calendar) { instance_double("Calendar") }
    let(:config) { CalendarAssistant::Config.new options: config_options }
    let(:config_options) { Hash.new }
    let(:token_store) { instance_double("CalendarAssistant::Config::TokenStore") }
    let(:event_repository) { instance_double("EventRepository") }
    let(:event_repository_factory) { instance_double("EventRepositoryFactory") }
    let(:ca) { CalendarAssistant.new config, event_repository_factory: event_repository_factory }
    let(:event_array) { [instance_double("Event"), instance_double("Event")] }
    let(:events) { instance_double("Events", :items => event_array ) }
    let(:authorizer) { instance_double("Authorizer") }
    let(:event_set) { CalendarAssistant::EventSet.new(event_repository, []) }

    before do
      allow(CalendarAssistant::Authorizer).to receive(:new).and_return(authorizer)
      allow(config).to receive(:token_store).and_return(token_store)
      allow(config).to receive(:profile_name).and_return("profile-name")
      allow(authorizer).to receive(:service).and_return(service)
      allow(event_repository).to receive(:find).and_return(event_set)
      allow(service).to receive(:get_calendar).and_return(calendar)
      allow(event_repository_factory).to receive(:new_event_repository).and_return(event_repository)
      allow(calendar).to receive(:time_zone).and_return("Europe/London")
    end

    describe "#find_events" do
      let(:time) { Time.now.beginning_of_day..(Time.now + 1.day).end_of_day }

      it "calls through to the repository" do
        expect(event_repository).to receive(:find).with(time)
        ca.find_events(time)
      end
    end

    describe "#find_location_events" do
      let(:event_repository) { instance_double("EventRepository") }
      let(:location_event) { instance_double("Event", :location_event? => true) }
      let(:other_event) { instance_double("Event", :location_event? => false) }
      let(:events) { [location_event, other_event].shuffle }
      let(:event_set) { CalendarAssistant::EventSet.new(event_repository, events) }

      it "selects location events from event repository find" do
        time = Time.now.beginning_of_day..(Time.now + 1.day).end_of_day

        expect(event_repository).to receive(:find).with(time).and_return(event_set)

        result = ca.find_location_events time
        expect(result.events).to eq([location_event])
      end
    end

    describe "#create_location_event" do
      let(:new_event) do
        CalendarAssistant::Event.new(instance_double("GCal::Event", {
                          id: SecureRandom.uuid,
                          start: new_event_start,
                          end: new_event_end
                        }))
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
          attributes = {
              start: new_event_start.date,
              end: new_event_end.date,
              summary: "#{CalendarAssistant::EMOJI_WORLDMAP}  WFH",
              transparency: CalendarAssistant::Event::Transparency::TRANSPARENT
          }

          expect(event_repository).to receive(:create).with(attributes).and_return(new_event)

          response = ca.create_location_event CalendarAssistant::CLIHelpers.parse_datespec("today"), "WFH"
          expect(response.events[:created]).to eq([new_event])
        end
      end

      context "called with a Date Range" do
        let(:new_event_start_date) { Date.parse("2019-09-03") }
        let(:new_event_end_date) { Date.parse("2019-09-05") }

        it "creates an appropriately-titled transparent all-day event" do
          attributes = {
              start: new_event_start.date,
              end: new_event_end.date,
              summary: "#{CalendarAssistant::EMOJI_WORLDMAP}  WFH",
              transparency: CalendarAssistant::Event::Transparency::TRANSPARENT
          }

          expect(event_repository).to receive(:create).with(attributes).and_return(new_event)

          response = ca.create_location_event new_event_start_date..new_event_end_date, "WFH"
          expect(response.events[:created]).to eq([new_event])
        end
      end

      context "when there's a pre-existing location event" do
        let(:existing_event_start) { GCal::EventDateTime.new date: existing_event_start_date }
        let(:existing_event_end) { GCal::EventDateTime.new date: (existing_event_end_date + 1.day) } # always one day later than actual end

        let(:new_event_start_date) { Date.parse("2019-09-03") }
        let(:new_event_end_date) { Date.parse("2019-09-05") }

        let(:existing_event) do
          CalendarAssistant::Event.new(instance_double("GCal::Event", {
                            id: SecureRandom.uuid,
                            start: existing_event_start,
                            end: existing_event_end
                          }))
        end

        before do
          attributes = {
              start: new_event_start.date,
              end: new_event_end.date,
              summary: "#{CalendarAssistant::EMOJI_WORLDMAP}  WFH",
              transparency: CalendarAssistant::Event::Transparency::TRANSPARENT
          }

          expect(event_repository).to receive(:create).with(attributes).and_return(new_event)
          expect(ca).to receive(:find_location_events).
                          and_return(CalendarAssistant::EventSet.new(event_repository, [existing_event]))
        end

        context "when the new event is entirely within the range of the pre-existing event" do
          let(:existing_event_start_date) { new_event_start_date }
          let(:existing_event_end_date) { new_event_end_date }

          it "removes the pre-existing event" do
            expect(event_repository).to receive(:delete).with(existing_event)

            response = ca.create_location_event new_event_start_date..new_event_end_date, "WFH"
            expect(response.events[:created]).to eq([new_event])
            expect(response.events[:deleted]).to eq([existing_event])
          end
        end

        context "when the new event overlaps the start of the pre-existing event" do
          let(:existing_event_start_date) { Date.parse("2019-09-04") }
          let(:existing_event_end_date) { Date.parse("2019-09-06") }

          it "shrinks the pre-existing event" do
            expect(event_repository).to receive(:update).with(existing_event, start: existing_event_end_date)

            response = ca.create_location_event new_event_start_date..new_event_end_date, "WFH"
            expect(response.events[:created]).to eq([new_event])
            expect(response.events[:modified]).to eq([existing_event])
          end
        end

        context "when the new event overlaps the end of the pre-existing event" do
          let(:existing_event_start_date) { Date.parse("2019-09-02") }
          let(:existing_event_end_date) { Date.parse("2019-09-04") }

          it "shrinks the pre-existing event" do
            expect(event_repository).to receive(:update).with(existing_event, end: new_event_start_date )

            response = ca.create_location_event new_event_start_date..new_event_end_date, "WFH"
            expect(response.events[:created]).to eq([new_event])
            expect(response.events[:modified]).to eq([existing_event])
          end
        end

        context "when the new event is completely overlapped by the pre-existing event" do
          let(:existing_event_start_date) { Date.parse("2019-09-02") }
          let(:existing_event_end_date) { Date.parse("2019-09-06") }

          it "shrinks the pre-existing event" do
            expect(event_repository).to receive(:update).with(existing_event, start: existing_event_end_date)

            response = ca.create_location_event new_event_start_date..new_event_end_date, "WFH"
            expect(response.events[:created]).to eq([new_event])
            expect(response.events[:modified]).to eq([existing_event])
          end
        end
      end
    end

    describe "#availability" do
      let(:scheduler) { instance_double(CalendarAssistant::Scheduler) }
      let(:time_range) { instance_double("time range") }

      context "looking at own calendar" do
        before do
          expect(event_repository_factory).to receive(:new_event_repository).
                                                with(anything, CalendarAssistant::Config::DEFAULT_CALENDAR_ID).
                                                and_return(event_repository)
        end

        it "creates a scheduler and invokes #available_blocks" do
          expect(CalendarAssistant::Scheduler).to receive(:new).
                                                    with(ca, event_repository).
                                                    and_return(scheduler)
          expect(scheduler).to receive(:available_blocks).with(time_range).and_return(event_set)

          response = ca.availability(time_range)

          expect(response).to eq(event_set)
        end
      end

      context "looking at someone else's calendar" do
        let(:other_calendar_id) { "somebodyelse@example.com" }
        let(:config_options) do
          {
            CalendarAssistant::Config::Keys::Options::ATTENDEES => other_calendar_id,
          }
        end

        before do
          expect(event_repository_factory).to receive(:new_event_repository).
                                                with(anything, other_calendar_id).
                                                and_return(event_repository)
        end

        it "creates a scheduler and invokes #available_blocks" do
          expect(CalendarAssistant::Scheduler).to receive(:new).
                                                    with(ca, event_repository).
                                                    and_return(scheduler)
          expect(scheduler).to receive(:available_blocks).with(time_range).and_return(event_set)

          response = ca.availability(time_range)

          expect(response).to eq(event_set)
        end
      end
    end

    describe "#in_env" do
      let(:config_options) do
        {
          CalendarAssistant::Config::Keys::Settings::START_OF_DAY => "7am",
          CalendarAssistant::Config::Keys::Settings::END_OF_DAY => "3pm",
        }
      end

      it "sets beginning and end of workday and restores them" do
        BusinessTime::Config.beginning_of_workday = "6am"
        BusinessTime::Config.end_of_workday = "2pm"
        ca.in_env do
          expect(BusinessTime::Config.beginning_of_workday.hour).to eq(7)
          expect(BusinessTime::Config.end_of_workday.hour).to eq(15)
        end
        expect(BusinessTime::Config.beginning_of_workday.hour).to eq(6)
        expect(BusinessTime::Config.end_of_workday.hour).to eq(14)
      end

      it "exceptionally restores beginning and end of workday" do
        BusinessTime::Config.beginning_of_workday = "6am"
        BusinessTime::Config.end_of_workday = "2pm"
        ca.in_env do
          raise RuntimeError
        rescue
        end
        expect(BusinessTime::Config.beginning_of_workday.hour).to eq(6)
        expect(BusinessTime::Config.end_of_workday.hour).to eq(14)
      end

      it "calls in_tz with the calendar timezone" do
        expect(ca).to receive(:in_tz)
        ca.in_env do ; end
      end
    end

    describe "#in_tz" do
      before do
        expect(calendar).to receive(:time_zone).and_return("a time zone id")
      end

      it "calls .in_tz with the default calendar's time zone" do
        expect(CalendarAssistant).to receive(:in_tz).with("a time zone id")
        ca.in_tz do ; end
      end
    end

    describe "#event_repository" do
      it "invokes the factory method to create a new repository" do
        expect(event_repository_factory).to receive(:new_event_repository).with(service, "foo")
        ca.event_repository("foo")
      end

      it "caches the result" do
        expect(event_repository_factory).to receive(:new_event_repository).once
        ca.event_repository("foo")
        ca.event_repository("foo")
      end
    end
  end
end
