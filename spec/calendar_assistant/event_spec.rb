require 'date'

describe CalendarAssistant::Event do
  #
  #  factory bit
  #
  let(:attendee_self) do
    GCal::EventAttendee.new display_name: "Attendee Self",
                            email: "attendee-self@example.com",
                            response_status: GCal::Event::Response::ACCEPTED,
                            self: true
  end

  let(:attendee_room_resource) do
    GCal::EventAttendee.new display_name: "Attendee Room",
                            email: "attendee-room@example.com",
                            response_status: GCal::Event::Response::ACCEPTED,
                            resource: true
  end

  let(:attendee_optional) do
    GCal::EventAttendee.new display_name: "Attendee Optional",
                            email: "attendee-optional@example.com",
                            response_status: GCal::Event::Response::ACCEPTED,
                            optional: true
  end

  let(:attendee_required) do
    GCal::EventAttendee.new display_name: "Attendee Required",
                            email: "attendee-required@example.com",
                            response_status: GCal::Event::Response::ACCEPTED
  end

  let(:attendee_organizer) do
    GCal::EventAttendee.new display_name: "Attendee Organizer",
                            email: "attendee-organizer@example.com",
                            response_status: GCal::Event::Response::ACCEPTED,
                            organizer: true
  end

  let(:attendee_group) do
    GCal::EventAttendee.new display_name: "Attendee Group",
                            email: "attendee-group@example.com",
                            response_status: GCal::Event::Response::NEEDS_ACTION
  end

  let(:attendees) do
    [attendee_self, attendee_room_resource, attendee_optional, attendee_required, attendee_organizer, attendee_group]
  end

  let(:decorated_class) { Google::Apis::CalendarV3::Event }
  let(:decorated_object) { decorated_class.new }
  subject { described_class.new decorated_object }

  describe "#location_event?" do
    context "event summary does not begin with a worldmap emoji" do
      let(:decorated_object) { decorated_class.new(summary: "not a location event") }

      it "returns false" do
        expect(subject.location_event?).to be_falsey
      end
    end

    context "event summary begins with a worldmap emoji" do
      let(:decorated_object) { decorated_class.new(summary: "#{CalendarAssistant::EMOJI_WORLDMAP} yes a location event") }

      it "returns true" do
        expect(subject.location_event?).to be_truthy
      end
    end
  end

  describe "#all_day?" do
    context "event has start and end dates" do
      let(:decorated_object) do
        decorated_class.new start: GCal::EventDateTime.new(date: Date.today),
                            end: GCal::EventDateTime.new(date: Date.today + 1)
      end

      it { expect(subject.all_day?).to be_truthy }
    end

    context "event has just a start date" do
      let(:decorated_object) { decorated_class.new(start: GCal::EventDateTime.new(date: Date.today)) }

      it { expect(subject.all_day?).to be_truthy }
    end

    context "event has just an end date" do
      let(:decorated_object) { decorated_class.new(end: GCal::EventDateTime.new(date: Date.today + 1)) }

      it { expect(subject.all_day?).to be_truthy }
    end

    context "event has start and end times" do
      let(:decorated_object) do
        decorated_class.new start: GCal::EventDateTime.new(date_time: Time.now),
                            end: GCal::EventDateTime.new(date_time: Time.now + 30.minutes)
      end

      it { expect(subject.all_day?).to be_falsey }
    end
  end

  describe "#future?" do
    freeze_time
    let(:decorated_object) { decorated_class.new(end: GCal::EventDateTime.new(date: Date.today + 7)) }

    context "all day event" do

      it "return true if the events starts later than today" do
        expect(subject.update(start: GCal::EventDateTime.new(date: Date.today - 1)).future?).to be_falsey
        expect(subject.update(start: GCal::EventDateTime.new(date: Date.today)).future?).to be_falsey
        expect(subject.update(start: GCal::EventDateTime.new(date: Date.today + 1)).future?).to be_truthy
      end
    end

    context "intraday event" do
      let(:decorated_object) { decorated_class.new(end: GCal::EventDateTime.new(date_time: Time.now + 30.minutes)) }

      it "returns true if the event starts later than now" do
        expect(subject.update(start: GCal::EventDateTime.new(date_time: Time.now - 1)).future?).to be_falsey
        expect(subject.update(start: GCal::EventDateTime.new(date_time: Time.now)).future?).to be_falsey
        expect(subject.update(start: GCal::EventDateTime.new(date_time: Time.now + 1)).future?).to be_truthy
      end
    end
  end

  describe "#past?" do
    freeze_time

    context "all day event" do
      let(:decorated_object) { decorated_class.new(start: GCal::EventDateTime.new(date: Date.today - 7)) }

      it "returns true if the event ends today or later" do
        expect(subject.update(end: GCal::EventDateTime.new(date: Date.today - 1)).past?).to be_truthy
        expect(subject.update(end: GCal::EventDateTime.new(date: Date.today)).past?).to be_truthy
        expect(subject.update(end: GCal::EventDateTime.new(date: Date.today + 1)).past?).to be_falsey
      end
    end

    context "intraday event" do
      let(:decorated_object) { decorated_class.new(start: GCal::EventDateTime.new(date_time: Time.now - 30.minutes)) }

      it "returns true if the event ends now or later" do
        expect(subject.update(end: GCal::EventDateTime.new(date_time: Time.now - 1)).past?).to be_truthy
        expect(subject.update(end: GCal::EventDateTime.new(date_time: Time.now)).past?).to be_truthy
        expect(subject.update(end: GCal::EventDateTime.new(date_time: Time.now + 1)).past?).to be_falsey
      end
    end
  end

  describe "#declined?" do
    context "event with no attendees" do
      it { is_expected.not_to be_declined }
    end

    context "event with attendees including me" do
      let(:decorated_object) { decorated_class.new(attendees: attendees) }

      (GCal::Event::RealResponse.constants - [:DECLINED]).each do |response_status_name|
        context "response status #{response_status_name}" do
          before do
            allow(attendee_self).to receive(:response_status).
                                      and_return(GCal::Event::Response.const_get(response_status_name))
          end

          it { expect(subject.declined?).to be_falsey }
        end
      end

      context "response status DECLINED" do
        before do
          allow(attendee_self).to receive(:response_status).and_return(GCal::Event::Response::DECLINED)
        end

        it { expect(subject.declined?).to be_truthy }
      end
    end

    context "event with attendees but not me" do
      let(:decorated_object) { decorated_class.new(attendees: attendees - [attendee_self]) }

      it { expect(subject.declined?).to be_falsey }
    end
  end

  describe "#accepted?" do
    context "event with no attendees" do
      it { is_expected.not_to be_accepted }
    end

    context "event with attendees including me" do
      let(:decorated_object) { decorated_class.new(attendees: attendees) }

      (GCal::Event::RealResponse.constants - [:ACCEPTED]).each do |response_status_name|
        context "response status #{response_status_name}" do
          before do
            allow(attendee_self).to receive(:response_status).
                                      and_return(GCal::Event::Response.const_get(response_status_name))
          end

          it { expect(subject.accepted?).to be_falsey }
        end
      end

      context "response status ACCEPTED" do
        before do
          allow(attendee_self).to receive(:response_status).and_return(GCal::Event::Response::ACCEPTED)
        end

        it { expect(subject.accepted?).to be_truthy }
      end
    end

    context "event with attendees but not me" do
      let(:decorated_object) { decorated_class.new(attendees: attendees - [attendee_self]) }

      it { expect(subject.accepted?).to be_falsey }
    end
  end

  describe "#awaiting?" do
    context "event with no attendees" do
      it { is_expected.not_to be_awaiting }
    end

    context "event with attendees including me" do
      let(:decorated_object) { decorated_class.new(attendees: attendees) }

      (GCal::Event::RealResponse.constants - [:NEEDS_ACTION]).each do |response_status_name|
        context "response status #{response_status_name}" do
          before do
            allow(attendee_self).to receive(:response_status).
                                      and_return(GCal::Event::Response.const_get(response_status_name))
          end

          it { expect(subject.awaiting?).to be_falsey }
        end
      end

      context "response status NEEDS_ACTION" do
        before do
          allow(attendee_self).to receive(:response_status).and_return(GCal::Event::Response::NEEDS_ACTION)
        end

        it { expect(subject.awaiting?).to be_truthy }
      end
    end

    context "event with attendees but not me" do
      let(:decorated_object) { decorated_class.new(attendees: attendees - [attendee_self]) }

      it { expect(subject.awaiting?).to be_falsey }
    end
  end

  describe "#one_on_one?" do
    context "event with no attendees" do
      it { is_expected.not_to be_one_on_one }
    end

    context "event with two attendees" do
      context "neither is me" do
        let(:decorated_object) { decorated_class.new(attendees: [attendee_required, attendee_organizer]) }

        it { is_expected.not_to be_one_on_one }
      end

      context "one is me" do
        let(:decorated_object) { decorated_class.new(attendees: [attendee_self, attendee_required]) }

        it { is_expected.to be_one_on_one }
      end
    end

    context "event with three attendees, one of which is me" do
      let(:decorated_object) { decorated_class.new(attendees: [attendee_self, attendee_organizer, attendee_required]) }

      it { is_expected.not_to be_one_on_one }

      context "one is a room" do
        let(:decorated_object) { decorated_class.new(attendees: [attendee_self, attendee_organizer, attendee_room_resource]) }

        it { is_expected.to be_one_on_one }
      end
    end
  end

  describe "#busy?" do
    context "event is transparent" do
      let(:decorated_object) { decorated_class.new(transparency: GCal::Event::Transparency::TRANSPARENT) }

      it { is_expected.not_to be_busy }
    end

    context "event is opaque" do
      context "explicitly" do
        let(:decorated_object) { decorated_class.new(transparency: GCal::Event::Transparency::OPAQUE) }

        it { is_expected.to be_busy }
      end

      context "implicitly" do
        let(:decorated_object) { decorated_class.new(transparency: GCal::Event::Transparency::OPAQUE) }

        it { is_expected.to be_busy }
      end
    end
  end

  describe "#commitment?" do
    context "with no attendees" do
      it { is_expected.not_to be_commitment }
    end

    context "with attendees" do
      let(:decorated_object) { decorated_class.new(attendees: attendees) }

      (GCal::Event::RealResponse.constants - [:DECLINED]).each do |response_status_name|
        context "response is #{response_status_name}" do
          before do
            allow(attendee_self).to receive(:response_status).
                                      and_return(GCal::Event::Response.const_get(response_status_name))
          end

          it { is_expected.to be_commitment }
        end
      end

      context "response status DECLINED" do
        before do
          allow(attendee_self).to receive(:response_status).
                                    and_return(GCal::Event::Response::DECLINED)
        end

        it { is_expected.not_to be_commitment }
      end
    end
  end

  describe "#public?" do
    context "visibility is private" do
      let(:decorated_object) { decorated_class.new(visibility: GCal::Event::Visibility::PRIVATE) }
      it { is_expected.not_to be_public }
    end

    context "visibility is nil" do
      it { is_expected.not_to be_public }
    end

    context "visibility is default" do
      let(:decorated_object) { decorated_class.new(visibility: GCal::Event::Visibility::DEFAULT) }
      it { is_expected.not_to be_public }
    end

    context "visibility is public" do
      let(:decorated_object) { decorated_class.new(visibility: GCal::Event::Visibility::PUBLIC) }

      it { is_expected.to be_public }
    end
  end

  describe "#private?" do
    context "visibility is private" do
      let(:decorated_object) { decorated_class.new(visibility: GCal::Event::Visibility::PRIVATE) }
      it { is_expected.to be_private }
    end

    context "visibility is nil" do
      it { is_expected.not_to be_private }
    end

    context "visibility is default" do
      let(:decorated_object) { decorated_class.new(visibility: GCal::Event::Visibility::DEFAULT) }
      it { is_expected.not_to be_private }
    end

    context "visibility is public" do
      let(:decorated_object) { decorated_class.new(visibility: GCal::Event::Visibility::PUBLIC) }
      it { is_expected.not_to be_private }
    end
  end

  describe "#explicit_visibility?" do
    context "when visibility is private" do
      let(:decorated_object) { decorated_class.new(visibility: GCal::Event::Visibility::PRIVATE) }
      it { is_expected.to be_explicit_visibility }
    end

    context "when visibility is public" do
      let(:decorated_object) { decorated_class.new(visibility: GCal::Event::Visibility::PUBLIC) }
      it { is_expected.to be_explicit_visibility }
    end

    context "when visibility is default" do
      let(:decorated_object) { decorated_class.new(visibility: GCal::Event::Visibility::DEFAULT) }
      it { is_expected.not_to be_explicit_visibility }
    end

    context "when visibility is nil" do
      let(:decorated_object) { decorated_class.new(visibility: nil) }
      it { is_expected.not_to be_explicit_visibility }
    end
  end

  describe "#current?" do
    it "is the past" do
      allow(subject).to receive(:past?).and_return(true)
      allow(subject).to receive(:future?).and_return(false)

      expect(subject.current?).to be_falsey
    end

    it "isn't the past or the future" do
      allow(subject).to receive(:past?).and_return(false)
      allow(subject).to receive(:future?).and_return(false)

      expect(subject.current?).to be_truthy
    end

    it "is the future" do
      allow(subject).to receive(:past?).and_return(false)
      allow(subject).to receive(:future?).and_return(true)

      expect(subject.current?).to be_falsey
    end
  end

  describe "#start_time" do
    context "all day event" do
      let(:start_date) { Date.today }

      context "containing a Date" do
        let(:decorated_object) { decorated_class.new(start: GCal::EventDateTime.new(date: start_date)) }
        it { expect(subject.start_time).to eq(start_date.beginning_of_day) }
      end

      context "containing a String" do
        let(:decorated_object) { decorated_class.new(start: GCal::EventDateTime.new(date: start_date.to_s)) }
        it { expect(subject.start_time).to eq(start_date.beginning_of_day) }
      end
    end

    context "intraday event" do
      let(:start_time) { Time.now }

      let(:decorated_object) { decorated_class.new(start: GCal::EventDateTime.new(date_time: start_time)) }
      it { expect(subject.start_time).to eq(start_time) }
    end
  end

  describe "#start_date" do
    context "all day event" do
      let(:start_date) { Date.today }

      context "containing a Date" do
        let(:decorated_object) { decorated_class.new(start: GCal::EventDateTime.new(date: start_date)) }
        it { expect(subject.start_date).to eq(start_date) }
      end

      context "containing a String" do
        let(:decorated_object) { decorated_class.new(start: GCal::EventDateTime.new(date: start_date.to_s)) }
        it { expect(subject.start_date).to eq(start_date) }
      end
    end

    context "intraday event" do
      let(:start_time) { Time.now }

      let(:decorated_object) { decorated_class.new(start: GCal::EventDateTime.new(date_time: start_time)) }
      it { expect(subject.start_date).to eq(start_time.to_date) }
    end
  end

  describe "#end_time" do
    context "all day event" do
      let(:end_date) { Date.today }

      context "containing a Date" do
        let(:decorated_object) { decorated_class.new(end: GCal::EventDateTime.new(date: end_date)) }
        it { expect(subject.end_time).to eq(end_date.beginning_of_day) }
      end

      context "containing a String" do
        let(:decorated_object) { decorated_class.new(end: GCal::EventDateTime.new(date: end_date.to_s)) }
        it { expect(subject.end_time).to eq(end_date.beginning_of_day) }
      end
    end

    context "intraday event" do
      let(:end_time) { Time.now }

      let(:decorated_object) { decorated_class.new(end: GCal::EventDateTime.new(date_time: end_time)) }
      it { expect(subject.end_time).to eq(end_time) }
    end
  end

  describe "#end_date" do
    context "all day event" do
      let(:end_date) { Date.today }

      context "containing a Date" do
        let(:decorated_object) { decorated_class.new(end: GCal::EventDateTime.new(date: end_date)) }
        it { expect(subject.end_date).to eq(end_date) }
      end

      context "containing a String" do
        let(:decorated_object) { decorated_class.new(end: GCal::EventDateTime.new(date: end_date.to_s)) }
        it { expect(subject.end_date).to eq(end_date) }
      end
    end

    context "intraday event" do
      let(:end_time) { Time.now }

      let(:decorated_object) { decorated_class.new(end: GCal::EventDateTime.new(date_time: end_time)) }
      it { expect(subject.end_date).to eq(end_time.to_date) }
    end
  end

  describe "#view_summary" do
    context "event is not private" do
      context "and summary exists" do
        let(:decorated_object) { decorated_class.new(summary: "my summary") }
        it { expect(subject.view_summary).to eq("my summary") }
      end

      context "and summary is blank" do
        let(:decorated_object) { decorated_class.new(summary: "") }
        it { expect(subject.view_summary).to eq("(no title)") }
      end

      context "and summary is nil" do
        let(:decorated_object) { decorated_class.new(summary: nil) }
        it { expect(subject.view_summary).to eq("(no title)") }
      end
    end

    context "event is private" do
      context "but we have access" do
        let(:decorated_object) { decorated_class.new(summary: "don't ignore", visibility: GCal::Event::Visibility::PRIVATE) }
        it { expect(subject.view_summary).to eq("don't ignore") }
      end

      context "and we do not have access" do
        let(:decorated_object) { decorated_class.new(visibility: GCal::Event::Visibility::PRIVATE) }
        it { expect(subject.view_summary).to eq("(private)") }
      end
    end
  end

  describe "#duration" do
    context "for a one-day all-day event" do
      let(:decorated_object) do
        decorated_class.new start: GCal::EventDateTime.new(date: Date.today),
                            end: GCal::EventDateTime.new(date: Date.today + 1)
      end

      it { expect(subject.duration).to eq("1d") }
    end

    context "for an multi-day all-day event" do
      let(:decorated_object) do
        decorated_class.new start: GCal::EventDateTime.new(date: Date.today),
                            end: GCal::EventDateTime.new(date: Date.today + 3)
      end

      it { expect(subject.duration).to eq("3d") }
    end

    context "for an intraday event" do
      let(:decorated_object) do
        decorated_class.new start: GCal::EventDateTime.new(date_time: Time.now),
                            end: GCal::EventDateTime.new(date_time: Time.now + 150.minutes)
      end

      it { expect(subject.duration).to eq("2h 30m") }
    end
  end

  describe "#human_attendees" do
    context "there are no attendees" do
      it { expect(subject.human_attendees).to be_nil }
    end

    context "there are attendees including people and rooms"  do
      let(:decorated_object) { decorated_class.new(attendees: attendees) }

      it "removes room resources from the list of attendees" do
        expect(subject.human_attendees).to eq(attendees - [attendee_room_resource])
      end
    end
  end

  describe "#attendee" do
    context "there are no attendees" do
      it "returns nil" do
        expect(subject.attendee(attendee_self.email)).to eq(nil)
        expect(subject.attendee(attendee_organizer.email)).to eq(nil)
        expect(subject.attendee("no-such-attendee@example.com")).to eq(nil)
      end
    end

    context "there are attendees"  do
      let(:decorated_object) { decorated_class.new(attendees: attendees) }

      it "looks up an EventAttendee by email, or returns nil" do
        expect(subject.attendee(attendee_self.email)).to eq(attendee_self)
        expect(subject.attendee(attendee_organizer.email)).to eq(attendee_organizer)
        expect(subject.attendee("no-such-attendee@example.com")).to eq(nil)
      end
    end
  end

  describe "#response_status" do
    context "event with no attendees (i.e. for just myself)" do
      it { expect(subject.response_status).to eq(GCal::Event::Response::SELF) }
    end

    context "event with attendees including me" do
      before { allow(attendee_self).to receive(:response_status).and_return("my-response-status") }
      let(:decorated_object) { decorated_class.new attendees: attendees }

      it { expect(subject.response_status).to eq("my-response-status") }
    end

    context "event with attendees but not me" do
      let(:decorated_object) { decorated_class.new attendees: attendees - [attendee_self] }

      it { expect(subject.response_status).to eq(nil) }
    end
  end

  describe "av_uri" do
    context "location has a zoom link" do
      let(:decorated_object) do
        decorated_class.new location: "zoom at https://company.zoom.us/j/123412341 please", hangout_link: nil
      end

      it "returns the URI" do
        expect(subject.av_uri).to eq("https://company.zoom.us/j/123412341")
      end
    end

    context "description has a zoom link" do
      let(:decorated_object) do
        decorated_class.new description: "zoom at https://company.zoom.us/j/123412341 please",
                            hangout_link: nil
      end

      it "returns the URI" do
        expect(subject.av_uri).to eq("https://company.zoom.us/j/123412341")
      end
    end

    context "has a hangout link" do
      let(:decorated_object) do
        decorated_class.new description: "see you in the hangout",
                            hangout_link: "https://plus.google.com/hangouts/_/company.com/yerp?param=random"
      end

      it "returns the URI" do
        expect(subject.av_uri).to eq("https://plus.google.com/hangouts/_/company.com/yerp?param=random")
      end
    end

    context "has no known av links" do
      let(:decorated_object) do
        decorated_class.new description: "we'll meet in person",
                            hangout_link: nil
      end

      it "returns nil" do
        expect(subject.av_uri).to be_nil
      end
    end
  end
end
