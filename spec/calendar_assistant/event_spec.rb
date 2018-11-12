require 'date'

describe CalendarAssistant::Event do
  let(:decorated_class) { Google::Apis::CalendarV3::Event }

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

  subject { described_class.new decorated_class.new }

  describe "#location_event?" do
    context "event summary does not begin with a worldmap emoji" do
      let(:decorated_object) { decorated_class.new(summary: "not a location event") }

      it "returns false" do
        expect(described_class.new(decorated_object).location_event?).to be_falsey
      end
    end

    context "event summary begins with a worldmap emoji" do
      let(:decorated_object) { decorated_class.new(summary: "🗺 yes a location event") }

      it "returns true" do
        expect(described_class.new(decorated_object).location_event?).to be_truthy
      end
    end
  end

  describe "#all_day?" do
    context "event has start and end dates" do
      let(:decorated_object) { decorated_class.new(start: GCal::EventDateTime.new(date: Date.today),
                                                   end: GCal::EventDateTime.new(date: Date.today + 1)) }
      subject do
        described_class.new decorated_object
      end

      it { expect(subject.all_day?).to be_truthy }
    end

    context "event has start and end times" do
      let(:decorated_object) { decorated_class.new(start: GCal::EventDateTime.new(date_time: Time.now),
                                                   end: GCal::EventDateTime.new(date_time: Time.now + 30.minutes)) }

      subject do
        described_class.new decorated_object
      end

      it { expect(subject.all_day?).to be_falsey }
    end
  end

  describe "#future?" do
    freeze_time
    let(:decorated_object) { decorated_class.new(end: GCal::EventDateTime.new(date: Date.today + 7)) }

    context "all day event" do
      subject { described_class.new decorated_object }

      it "return true if the events starts later than today" do
        expect(subject.update(start: GCal::EventDateTime.new(date: Date.today - 1)).future?).to be_falsey
        expect(subject.update(start: GCal::EventDateTime.new(date: Date.today)).future?).to be_falsey
        expect(subject.update(start: GCal::EventDateTime.new(date: Date.today + 1)).future?).to be_truthy
      end
    end

    context "intraday event" do
      let(:decorated_object) { decorated_class.new(end: GCal::EventDateTime.new(date_time: Time.now + 30.minutes)) }
      subject { described_class.new decorated_object }

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
      subject { described_class.new decorated_object }

      it "returns true if the event ends today or later" do
        expect(subject.update(end: GCal::EventDateTime.new(date: Date.today - 1)).past?).to be_truthy
        expect(subject.update(end: GCal::EventDateTime.new(date: Date.today)).past?).to be_truthy
        expect(subject.update(end: GCal::EventDateTime.new(date: Date.today + 1)).past?).to be_falsey
      end
    end

    context "intraday event" do
      let(:decorated_object) { decorated_class.new(start: GCal::EventDateTime.new(date_time: Time.now - 30.minutes)) }
      subject { described_class.new decorated_object }

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
      subject { described_class.new decorated_object }

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
          allow(attendee_self).to receive(:response_status).
              and_return(GCal::Event::Response::DECLINED)
        end

        it { expect(subject.declined?).to be_truthy }
      end
    end

    context "event with attendees but not me" do
      let(:decorated_object) { decorated_class.new(attendees: attendees - [attendee_self]) }
      subject { described_class.new decorated_object }

      it { expect(subject.declined?).to be_falsey }
    end
  end

  describe "#accepted?" do
    context "event with no attendees" do
      it { is_expected.not_to be_accepted }
    end

    context "event with attendees including me" do
      let(:decorated_object) { decorated_class.new(attendees: attendees) }
      subject { described_class.new decorated_object }

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
          allow(attendee_self).to receive(:response_status).
              and_return(GCal::Event::Response::ACCEPTED)
        end

        it { expect(subject.accepted?).to be_truthy }
      end
    end

    context "event with attendees but not me" do
      let(:decorated_object) { decorated_class.new(attendees: attendees - [attendee_self]) }
      subject { described_class.new decorated_object }

      it { expect(subject.accepted?).to be_falsey }
    end
  end

  describe "#awaiting?" do
    context "event with no attendees" do
      it { is_expected.not_to be_awaiting }
    end

    context "event with attendees including me" do
      let(:decorated_object) { decorated_class.new(attendees: attendees) }
      subject { described_class.new decorated_object }

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
          allow(attendee_self).to receive(:response_status).
              and_return(GCal::Event::Response::NEEDS_ACTION)
        end

        it { expect(subject.awaiting?).to be_truthy }
      end
    end

    context "event with attendees but not me" do
      let(:decorated_object) { decorated_class.new(attendees: attendees - [attendee_self]) }
      subject { described_class.new decorated_object }

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
        subject { described_class.new decorated_object }

        it { is_expected.not_to be_one_on_one }
      end

      context "one is me" do
        let(:decorated_object) { decorated_class.new(attendees: [attendee_self, attendee_required]) }
        subject { described_class.new decorated_object }

        it { is_expected.to be_one_on_one }
      end
    end

    context "event with three attendees, one of which is me" do
      let(:decorated_object) { decorated_class.new(attendees: [attendee_self, attendee_organizer, attendee_required]) }
      subject { described_class.new decorated_object }
      it { is_expected.not_to be_one_on_one }

      context "one is a room" do
        let(:decorated_object) { decorated_class.new(attendees: [attendee_self, attendee_organizer, attendee_room_resource]) }
        subject { described_class.new decorated_object }
        it { is_expected.to be_one_on_one }
      end
    end
  end

  describe "#busy?" do
    context "event is transparent" do
      let(:decorated_object) { decorated_class.new(transparency: GCal::Event::Transparency::TRANSPARENT) }
      subject { described_class.new(decorated_object) }
      it { is_expected.not_to be_busy }
    end

    context "event is opaque" do
      context "explicitly" do
        let(:decorated_object) { decorated_class.new(transparency: GCal::Event::Transparency::OPAQUE) }
        subject { described_class.new(decorated_object) }
        it { is_expected.to be_busy }
      end

      context "implicitly" do
        let(:decorated_object) { decorated_class.new(transparency: GCal::Event::Transparency::OPAQUE) }
        subject { described_class.new(decorated_object) }
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
      subject { described_class.new decorated_object }

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
      subject { described_class.new decorated_object }
      it { is_expected.not_to be_public }
    end

    context "visibility is nil" do
      subject { described_class.new(decorated_class.new) }
      it { is_expected.not_to be_public }
    end

    context "visibility is default" do
      let(:decorated_object) { decorated_class.new(visibility: GCal::Event::Visibility::DEFAULT) }
      subject { described_class.new decorated_object }
      it { is_expected.not_to be_public }
    end

    context "visibility is public" do
      let(:decorated_object) { decorated_class.new(visibility: GCal::Event::Visibility::PUBLIC) }
      subject { described_class.new decorated_object }
      it { is_expected.to be_public }
    end
  end

  describe "#private?" do
    context "visibility is private" do
      let(:decorated_object) { decorated_class.new(visibility: GCal::Event::Visibility::PRIVATE) }
      subject { described_class.new decorated_object }
      it { is_expected.to be_private }
    end

    context "visibility is nil" do
      subject { described_class.new(decorated_class.new) }
      it { is_expected.not_to be_private }
    end

    context "visibility is default" do
      let(:decorated_object) { decorated_class.new(visibility: GCal::Event::Visibility::DEFAULT) }
      subject { described_class.new decorated_object }
      it { is_expected.not_to be_private }
    end

    context "visibility is public" do
      let(:decorated_object) { decorated_class.new(visibility: GCal::Event::Visibility::PUBLIC) }
      subject { described_class.new decorated_object }
      it { is_expected.not_to be_private }
    end
  end

  describe "#explicit_visibility?" do
    subject { described_class.new decorated_object }

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
        subject { described_class.new(decorated_object).start_time }
        it { is_expected.to eq(start_date.beginning_of_day) }
      end

      context "containing a String" do
        let(:decorated_object) { decorated_class.new(start: GCal::EventDateTime.new(date: start_date.to_s)) }
        subject { described_class.new(decorated_object).start_time }
        it { is_expected.to eq(start_date.beginning_of_day) }
      end
    end

    context "intraday event" do
      let(:start_time) { Time.now }

      let(:decorated_object) { decorated_class.new(start: GCal::EventDateTime.new(date_time: start_time)) }
      subject { described_class.new(decorated_object).start_time }
      it { is_expected.to eq(start_time) }
    end
  end

  describe "#start_date" do
    context "all day event" do
      let(:start_date) { Date.today }

      context "containing a Date" do
        let(:decorated_object) { decorated_class.new(start: GCal::EventDateTime.new(date: start_date)) }
        subject { described_class.new(decorated_object).start_date }
        it { is_expected.to eq(start_date) }
      end

      context "containing a String" do
        let(:decorated_object) { decorated_class.new(start: GCal::EventDateTime.new(date: start_date.to_s)) }
        subject { described_class.new(decorated_object).start_date }
        it { is_expected.to eq(start_date) }
      end
    end

    context "intraday event" do
      let(:start_time) { Time.now }

      let(:decorated_object) { decorated_class.new(start: GCal::EventDateTime.new(date_time: start_time)) }
      subject { described_class.new(decorated_object).start_date }
      it { is_expected.to eq(start_time.to_date) }
    end
  end

  describe "#view_summary" do
    context "event is not private" do
      context "and summary exists" do
        let(:decorated_object) { decorated_class.new(summary: "my summary") }
        subject { described_class.new decorated_object }
        it { expect(subject.view_summary).to eq("my summary") }
      end

      context "and summary is blank" do
        let(:decorated_object) { decorated_class.new(summary: "") }
        subject { described_class.new decorated_object }
        it { expect(subject.view_summary).to eq("(no title)") }
      end

      context "and summary is nil" do
        let(:decorated_object) { decorated_class.new(summary: nil) }
        subject { described_class.new decorated_object }
        it { expect(subject.view_summary).to eq("(no title)") }
      end
    end

    context "event is private" do
      context "but we have access" do
        let(:decorated_object) { decorated_class.new(summary: "don't ignore this", visibility: GCal::Event::Visibility::PRIVATE) }
        subject { described_class.new decorated_object }
        it { expect(subject.view_summary).to eq("don't ignore this") }
      end

      context "and we do not have access" do
        let(:decorated_object) { decorated_class.new(visibility: GCal::Event::Visibility::PRIVATE) }
        subject { described_class.new decorated_object }
        it { expect(subject.view_summary).to eq("(private)") }
      end
    end
  end
end
