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
  #  other methods
  #

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
end