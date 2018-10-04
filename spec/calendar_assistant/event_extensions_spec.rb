# coding: utf-8
describe Google::Apis::CalendarV3::Event do
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


  #
  #  predicates
  #
  describe "#location_event?" do
    context "event summary does not begin with a worldmap emoji" do
      it "returns false" do
        expect(described_class.new(summary: "not a location event").location_event?).to be_falsey
      end
    end

    context "event summary begins with a worldmap emoji" do
      it "returns true" do
        expect(described_class.new(summary: "🗺 yes a location event").location_event?).to be_truthy
      end
    end
  end

  describe "#all_day?" do
    context "event has start and end dates" do
      subject do
        described_class.new start: GCal::EventDateTime.new(date: Date.today),
                            end: GCal::EventDateTime.new(date: Date.today + 1)
      end

      it { expect(subject.all_day?).to be_truthy }
    end

    context "event has start and end times" do
      subject do
        described_class.new start: GCal::EventDateTime.new(date_time: Time.now),
                            end: GCal::EventDateTime.new(date_time: Time.now + 30.minutes)
      end

      it { expect(subject.all_day?).to be_falsey }
    end
  end

  describe "#past?" do
    freeze_time

    context "all day event" do
      subject { described_class.new start: GCal::EventDateTime.new(date: Date.today - 7) }

      it "returns true if the event ends today or later" do
        expect(subject.update(end: GCal::EventDateTime.new(date: Date.today - 1)).past?).to be_truthy
        expect(subject.update(end: GCal::EventDateTime.new(date: Date.today)).past?).to be_truthy
        expect(subject.update(end: GCal::EventDateTime.new(date: Date.today + 1)).past?).to be_falsey
      end
    end

    context "intraday event" do
      subject { described_class.new start: GCal::EventDateTime.new(date_time: Time.now - 30.minutes) }

      it "returns true if the event ends now or later" do
        expect(subject.update(end: GCal::EventDateTime.new(date_time: Time.now - 1)).past?).to be_truthy
        expect(subject.update(end: GCal::EventDateTime.new(date_time: Time.now)).past?).to be_truthy
        expect(subject.update(end: GCal::EventDateTime.new(date_time: Time.now + 1)).past?).to be_falsey
      end
    end
  end

  describe "#future?" do
    freeze_time

    context "all day event" do
      subject { described_class.new end: GCal::EventDateTime.new(date: Date.today + 7) }

      it "return true if the events starts later than today" do
        expect(subject.update(start: GCal::EventDateTime.new(date: Date.today - 1)).future?).to be_falsey
        expect(subject.update(start: GCal::EventDateTime.new(date: Date.today)).future?).to be_falsey
        expect(subject.update(start: GCal::EventDateTime.new(date: Date.today + 1)).future?).to be_truthy
      end
    end

    context "intraday event" do
      subject { described_class.new end: GCal::EventDateTime.new(date_time: Time.now + 30.minutes) }

      it "returns true if the event starts later than now" do
        expect(subject.update(start: GCal::EventDateTime.new(date_time: Time.now - 1)).future?).to be_falsey
        expect(subject.update(start: GCal::EventDateTime.new(date_time: Time.now)).future?).to be_falsey
        expect(subject.update(start: GCal::EventDateTime.new(date_time: Time.now + 1)).future?).to be_truthy
      end
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

  describe "#declined?" do
    context "event with no attendees" do
      it { is_expected.not_to be_declined }
    end

    context "event with attendees including me" do
      subject { described_class.new attendees: attendees }

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
      subject { described_class.new attendees: attendees - [attendee_self] }

      it { expect(subject.declined?).to be_falsey }
    end
  end

  describe "#one_on_one?" do
    context "event with no attendees" do
      it { is_expected.not_to be_one_on_one }
    end

    context "event with two attendees" do
      context "neither is me" do
        subject { described_class.new attendees: [attendee_required, attendee_organizer] }

        it { is_expected.not_to be_one_on_one }
      end

      context "one is me" do
        subject { described_class.new attendees: [attendee_self, attendee_required] }

        it { is_expected.to be_one_on_one }
      end
    end

    context "event with three attendees, one of which is me" do
      subject { described_class.new attendees: [attendee_self, attendee_organizer, attendee_required] }
      it { is_expected.not_to be_one_on_one }

      context "one is a room" do
        subject { described_class.new attendees: [attendee_self, attendee_organizer, attendee_room_resource] }
        it { is_expected.to be_one_on_one }
      end
    end
  end

  describe "#busy?" do
    context "event is transparent" do
      subject { described_class.new(transparency: GCal::Event::Transparency::TRANSPARENT) }
      it { is_expected.not_to be_busy }
    end

    context "event is opaque" do
      context "explicitly" do
        subject { described_class.new(transparency: GCal::Event::Transparency::OPAQUE) }
        it { is_expected.to be_busy }
      end

      context "implicitly" do
        subject { described_class.new(transparency: GCal::Event::Transparency::OPAQUE) }
        it { is_expected.to be_busy }
      end
    end
  end

  describe "#commitment?" do
    context "with no attendees" do
      it { is_expected.not_to be_commitment }
    end

    context "with attendees" do
      subject { described_class.new attendees: attendees }

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

  describe "#private?" do
    context "visibility is private" do
      subject { described_class.new visibility: GCal::Event::Visibility::PRIVATE }
      it { is_expected.to be_private }
    end

    context "visibility is nil" do
      subject { described_class.new }
      it { is_expected.not_to be_private }
    end

    context "visibility is default" do
      subject { described_class.new visibility: GCal::Event::Visibility::DEFAULT }
      it { is_expected.not_to be_private }
    end

    context "visibility is public" do
      subject { described_class.new visibility: GCal::Event::Visibility::PUBLIC }
      it { is_expected.not_to be_private }
    end
  end

  #
  #  other methods
  #
  describe "#start_date" do
    context "all day event" do
      let(:start_date) { Date.today }

      context "containing a Date" do
        subject { described_class.new(start: GCal::EventDateTime.new(date: start_date)).start_date }
        it { is_expected.to eq(start_date) }
      end

      context "containing a string" do
        subject { described_class.new(start: GCal::EventDateTime.new(date: start_date.to_s)).start_date }
        it { is_expected.to eq(start_date) }
      end
    end

    context "intraday event" do
      let(:start_time) { Time.now }

      subject { described_class.new(start: GCal::EventDateTime.new(date_time: start_time)).start_date }
      it { is_expected.to eq(start_time.to_date) }
    end
  end

  describe "#human_attendees" do
    context "there are no attendees" do
      it { expect(subject.human_attendees).to be_nil }
    end

    context "there are attendees including people and rooms"  do
      subject { described_class.new(attendees: attendees) }

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
      subject { described_class.new(attendees: attendees) }

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
      subject { described_class.new attendees: attendees }

      it { expect(subject.response_status).to eq("my-response-status") }
    end

    context "event with attendees but not me" do
      subject { described_class.new attendees: attendees - [attendee_self] }

      it { expect(subject.response_status).to eq(nil) }
    end
  end

  describe "av_uri" do
    context "description has a zoom link" do
      let(:event) do
        described_class.new description: "zoom at https://company.zoom.us/j/123412341 please",
                            hangout_link: nil
      end

      it "returns the URI" do
        expect(event.av_uri).to eq("https://company.zoom.us/j/123412341")
      end
    end

    context "has a hangout link" do
      let(:event) do
        described_class.new description: "see you in the hangout",
                            hangout_link: "https://plus.google.com/hangouts/_/company.com/yerp?param=random"
      end

      it "returns the URI" do
        expect(event.av_uri).to eq("https://plus.google.com/hangouts/_/company.com/yerp?param=random")
      end
    end

    context "has no known av links" do
      let(:event) do
        described_class.new description: "we'll meet in person",
                            hangout_link: nil
      end

      it "returns nil" do
        expect(event.av_uri).to be_nil
      end
    end
  end

  describe "#view_summary" do
    context "event is not private" do
      context "and summary exists" do
        subject { described_class.new summary: "my summary" }
        it { expect(subject.view_summary).to eq("my summary") }
      end

      context "and summary is blank" do
        subject { described_class.new summary: "" }
        it { expect(subject.view_summary).to eq("(no title)") }
      end

      context "and summary is nil" do
        subject { described_class.new summary: nil }
        it { expect(subject.view_summary).to eq("(no title)") }
      end
    end

    context "event is private" do
      subject { described_class.new summary: "ignore this", visibility: GCal::Event::Visibility::PRIVATE }
      it { expect(subject.view_summary).to eq("(private)") }
    end
  end


  #
  #  recurrence-related methods that we're not really using yet
  #
  describe "#recurrence_rules?" do it end
  describe "#recurrence" do it end
  describe "#recurrence_parent" do it end
end

describe Google::Apis::CalendarV3::EventDateTime do
  describe "#to_date" do
    context "all day event" do
      context "storing a Date" do
        it { expect(described_class.new(date: Date.today).to_date).to be_a(Date) }
      end

      context "storing a string" do
        it { expect(described_class.new(date: "2018-09-01").to_date).to be_a(Date) }
      end
    end

    context "intraday event" do
      it { expect(described_class.new(date_time: Time.now).to_date).to be_nil }
    end
  end

  describe "#to_s" do
    context "date" do
      context "storing a Date" do
        subject { described_class.new date: Date.parse("2019-09-01") }
        it { expect(subject.to_s).to eq("2019-09-01") }
      end

      context "storing a string" do
        subject { described_class.new date: "2019-09-01" }
        it { expect(subject.to_s).to eq("2019-09-01") }
      end
    end

    context "time" do
      let(:time) { Time.parse "2019-09-01 13:14:15" }

      subject { described_class.new date_time: time }
      it { expect(subject.to_s).to eq("2019-09-01 13:14") }
    end
  end
end
