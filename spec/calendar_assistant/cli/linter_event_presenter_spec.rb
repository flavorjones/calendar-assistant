describe CalendarAssistant::CLI::LinterEventPresenter do
  let(:decorated_object) { CalendarAssistant::Event.new(Google::Apis::CalendarV3::Event.new(attendees: attendees)) }

  subject { described_class.new decorated_object }

  describe "attendees" do
    let(:attendee_self) do
      GCal::EventAttendee.new display_name: "Attendee Self",
                              email: "attendee-self@example.com",
                              response_status: CalendarAssistant::Event::Response::ACCEPTED,
                              self: true
    end

    let(:attendee_room_resource) do
      GCal::EventAttendee.new display_name: "Attendee Room",
                              email: "attendee-room@example.com",
                              response_status: CalendarAssistant::Event::Response::ACCEPTED,
                              resource: true
    end

    let(:attendee_optional) do
      GCal::EventAttendee.new display_name: "Attendee Optional",
                              email: "attendee-optional@example.com",
                              response_status: CalendarAssistant::Event::Response::ACCEPTED,
                              optional: true
    end

    let(:attendee_required) do
      GCal::EventAttendee.new display_name: "Attendee Required",
                              email: "attendee-required@example.com",
                              response_status: CalendarAssistant::Event::Response::ACCEPTED
    end

    let(:attendee_organizer) do
      GCal::EventAttendee.new display_name: "Attendee Organizer",
                              email: "attendee-organizer@example.com",
                              response_status: CalendarAssistant::Event::Response::DECLINED,
                              organizer: true
    end

    let(:attendee_group) do
      GCal::EventAttendee.new display_name: "Attendee Group",
                              email: "attendee-group@example.com",
                              response_status: CalendarAssistant::Event::Response::NEEDS_ACTION
    end

    let(:attendee_no_email) do
      GCal::EventAttendee.new display_name: "Attendee with no email",
                              response_status: CalendarAssistant::Event::Response::NEEDS_ACTION
    end

    let(:attendees) do
      [attendee_self, attendee_room_resource, attendee_optional, attendee_required, attendee_organizer, attendee_group, attendee_no_email]
    end

    context "when there are attendees" do
      context "and it's just me" do
        let(:attendees) { [attendee_self] }

        it "returns nothing" do
          expect(subject.attendees).to eq ""
        end
      end

      context "and there are other human attendees" do
        context "and there are four attendees" do
          it "returns a comma separated list, with emoji" do
            expect(subject.attendees).to eq "#{CalendarAssistant::CLI::LinterEventPresenter::EMOJI_ACCEPTED} attendee-required@example.com, #{CalendarAssistant::CLI::LinterEventPresenter::EMOJI_DECLINED} attendee-organizer@example.com, #{CalendarAssistant::CLI::LinterEventPresenter::EMOJI_NEEDS_ACTION} attendee-group@example.com, #{CalendarAssistant::CLI::LinterEventPresenter::EMOJI_NEEDS_ACTION} <no email>"
          end
        end

        context "and there are more than four attendees" do
          let(:attendees) do
            [].tap do |attendees|
              attendees.push *5.times.map { |i| GCal::EventAttendee.new(display_name: "Declined #{i}", email: "#{i}@example.com", response_status: CalendarAssistant::Event::Response::DECLINED) }
              attendees.push *10.times.map { |i| GCal::EventAttendee.new(display_name: "Accepted #{i}", email: "#{i}@example.com", response_status: CalendarAssistant::Event::Response::ACCEPTED) }
              attendees.push *40.times.map { |i| GCal::EventAttendee.new(display_name: "Needs Action #{i}", email: "#{i}@example.com", response_status: CalendarAssistant::Event::Response::NEEDS_ACTION) }
            end
          end
          it "shows a summary of accepts, declines and other by emoji" do
            expect(subject.attendees).to eq "#{CalendarAssistant::CLI::LinterEventPresenter::EMOJI_ACCEPTED} - 10, #{CalendarAssistant::CLI::LinterEventPresenter::EMOJI_DECLINED} - 5, #{CalendarAssistant::CLI::LinterEventPresenter::EMOJI_NEEDS_ACTION} - 40"
          end
        end
      end
    end

    context "when there are no attendees" do
      context "because attendees are empty" do
        let(:attendees) { [] }
        specify { expect(subject.attendees).to eq "" }
      end

      context "because attendees are nil" do
        let(:attendees) { nil }
        specify { expect(subject.attendees).to eq "" }
      end

      context "because attendees are not human" do
        let(:attendees) { [attendee_room_resource] }
        specify { expect(subject.attendees).to eq "" }
      end
    end
  end
end
