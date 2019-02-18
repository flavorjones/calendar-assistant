require "date"

describe CalendarAssistant::Event do
  it_behaves_like "an object that has duration" do
    let(:decorated_class) { Google::Apis::CalendarV3::Event }
    let(:decorated_object) { decorated_class.new(params) }

    let(:an_object) { described_class.new decorated_object }
  end

  describe "predicates" do
    it "lists all predicate methods with an arity of 0 in the PREDICATES constant" do
      instance = described_class.new(double)
      predicate_constant_methods = described_class::PREDICATES.values.flatten
      instance_predicates = instance.public_methods(false).select { |m| m =~ /\?$/ && instance.method(m).arity == 0 }

      expect(instance_predicates - predicate_constant_methods).to be_empty
    end
  end

  describe "instance methods" do
    #
    #  factory bit
    #
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
                              response_status: CalendarAssistant::Event::Response::ACCEPTED,
                              organizer: true
    end

    let(:attendee_group) do
      GCal::EventAttendee.new display_name: "Attendee Group",
                              email: "attendee-group@example.com",
                              response_status: CalendarAssistant::Event::Response::NEEDS_ACTION
    end

    let(:attendees) do
      [attendee_self, attendee_room_resource, attendee_optional, attendee_required, attendee_organizer, attendee_group]
    end

    let(:base_config) { { CalendarAssistant::Config::Keys::Settings::LOCATION_ICON => "<<IAMANICON>>" } }
    let(:config) { base_config }
    let(:decorated_class) { Google::Apis::CalendarV3::Event }
    let(:decorated_object) { decorated_class.new }
    subject { described_class.new decorated_object, config: config }

    describe "#update" do
      it "calls #update! and returns itself" do
        expect(subject).to receive(:update!).with({ :foo => 1, :bar => 2 })
        actual = subject.update :foo => 1, :bar => 2
        expect(actual).to eq(subject)
      end
    end

    describe "#location_event?" do
      context "event summary does not begin with a worldmap emoji" do
        let(:decorated_object) { decorated_class.new(summary: "not a location event") }

        it { expect(subject).not_to be_location_event }
      end

      context "no nickname is set" do
        context "event summary begins with a worldmap emoji" do
          let(:decorated_object) { decorated_class.new(summary: "<<IAMANICON>> yes a location event") }

          it { expect(subject).to be_location_event }
        end
      end

      context "a nickname is set" do
        let(:config) { base_config.merge({ CalendarAssistant::Config::Keys::Settings::NICKNAME => "Foo" }) }

        context "event summary begins with a worldmap emoji but not a prefix" do
          let(:decorated_object) { decorated_class.new(summary: "<<IAMANICON>> not a location event") }

          it { expect(subject).not_to be_location_event }
        end

        context "event summary begins with a worldmap emoji and a prefix and an @" do
          let(:decorated_object) { decorated_class.new(summary: "<<IAMANICON>> Foo @ a location event") }

          it { expect(subject).to be_location_event }
        end
      end
    end

    describe "#declined?" do
      context "event with no attendees" do
        it { is_expected.not_to be_declined }
      end

      context "event with attendees including me" do
        let(:decorated_object) { decorated_class.new(attendees: attendees) }

        (CalendarAssistant::Event::RealResponse.constants - [:DECLINED]).each do |response_status_name|
          context "response status #{response_status_name}" do
            before do
              allow(attendee_self).to receive(:response_status).
                                        and_return(CalendarAssistant::Event::Response.const_get(response_status_name))
            end

            it { expect(subject.declined?).to be_falsey }
          end
        end

        context "response status DECLINED" do
          before do
            allow(attendee_self).to receive(:response_status).and_return(CalendarAssistant::Event::Response::DECLINED)
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

        (CalendarAssistant::Event::RealResponse.constants - [:ACCEPTED]).each do |response_status_name|
          context "response status #{response_status_name}" do
            before do
              allow(attendee_self).to receive(:response_status).
                                        and_return(CalendarAssistant::Event::Response.const_get(response_status_name))
            end

            it { expect(subject.accepted?).to be_falsey }
          end
        end

        context "response status ACCEPTED" do
          before do
            allow(attendee_self).to receive(:response_status).and_return(CalendarAssistant::Event::Response::ACCEPTED)
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
        it { is_expected.not_to be_needs_action }
      end

      context "event with attendees including me" do
        let(:decorated_object) { decorated_class.new(attendees: attendees) }

        (CalendarAssistant::Event::RealResponse.constants - [:NEEDS_ACTION]).each do |response_status_name|
          context "response status #{response_status_name}" do
            before do
              allow(attendee_self).to receive(:response_status).
                                        and_return(CalendarAssistant::Event::Response.const_get(response_status_name))
            end

            it { expect(subject.awaiting?).to be_falsey }
            it { expect(subject.needs_action?).to be_falsey }
          end
        end

        context "response status NEEDS_ACTION" do
          before do
            allow(attendee_self).to receive(:response_status).and_return(CalendarAssistant::Event::Response::NEEDS_ACTION)
          end

          it { expect(subject.awaiting?).to be_truthy }
          it { expect(subject.needs_action?).to be_truthy }
        end
      end

      context "event with attendees but not me" do
        let(:decorated_object) { decorated_class.new(attendees: attendees - [attendee_self]) }

        it { expect(subject.awaiting?).to be_falsey }
        it { expect(subject.needs_action?).to be_falsey }
      end
    end

    describe "#tentative?" do
      context "event with no attendees" do
        it { is_expected.not_to be_tentative }
      end

      context "event with attendees including me" do
        let(:decorated_object) { decorated_class.new(attendees: attendees) }

        (CalendarAssistant::Event::RealResponse.constants - [:TENTATIVE]).each do |response_status_name|
          context "response status #{response_status_name}" do
            before do
              allow(attendee_self).to receive(:response_status).
                                        and_return(CalendarAssistant::Event::Response.const_get(response_status_name))
            end

            it { expect(subject.tentative?).to be_falsey }
          end
        end

        context "response status TENTATIVE" do
          before do
            allow(attendee_self).to receive(:response_status).and_return(CalendarAssistant::Event::Response::TENTATIVE)
          end

          it { expect(subject.tentative?).to be_truthy }
        end
      end

      context "event with attendees but not me" do
        let(:decorated_object) { decorated_class.new(attendees: attendees - [attendee_self]) }

        it { expect(subject.tentative?).to be_falsey }
      end
    end

    describe "#self?" do
      context "event with no attendees" do
        it { is_expected.to be_self }
      end

      context "event with attendees including me" do
        let(:decorated_object) { decorated_class.new(attendees: attendees) }

        (CalendarAssistant::Event::RealResponse.constants).each do |response_status_name|
          context "response status #{response_status_name}" do
            before do
              allow(attendee_self).to receive(:response_status).
                                        and_return(CalendarAssistant::Event::Response.const_get(response_status_name))
            end

            it { expect(subject.self?).to be_falsey }
          end
        end
      end

      context "event with attendees but not me" do
        let(:decorated_object) { decorated_class.new(attendees: attendees - [attendee_self]) }

        it { expect(subject.self?).to be_falsey }
      end
    end

    describe "#abandoned?" do
      context "event with no attendees" do
        it { is_expected.to_not be_abandoned }
      end

      context "event with non-visible guestlist" do
        let(:decorated_object) { decorated_class.new(attendees: [attendee_self]) }

        before do
          allow(subject).to receive(:visible_guestlist?).and_return(false)
        end

        it { is_expected.to_not be_abandoned }
      end

      context "event with attendees including me" do
        let(:decorated_object) { decorated_class.new(attendees: attendees) }

        (CalendarAssistant::Event::RealResponse.constants).each do |response_status_name|
          context "others' response status is #{response_status_name}" do
            before do
              attendees.each do |attendee|
                next if attendee == attendee_self
                allow(attendee).to receive(:response_status).
                                     and_return(CalendarAssistant::Event::Response.const_get(response_status_name))
              end
            end

            (CalendarAssistant::Event::RealResponse.constants).each do |my_response_status_name|
              context "my response status is #{my_response_status_name}" do
                before do
                  allow(attendee_self).to receive(:response_status).
                                            and_return(CalendarAssistant::Event::Response.const_get(my_response_status_name))
                end

                if CalendarAssistant::Event::Response.const_get(my_response_status_name) == CalendarAssistant::Event::RealResponse::DECLINED
                  it { is_expected.to_not be_abandoned }
                elsif CalendarAssistant::Event::Response.const_get(response_status_name) == CalendarAssistant::Event::RealResponse::DECLINED
                  it { is_expected.to be_abandoned }
                else
                  it { is_expected.to_not be_abandoned }
                end
              end
            end
          end
        end
      end

      context "event without me but with attendees who all declined" do
        let(:decorated_object) { decorated_class.new(attendees: attendees - [attendee_self]) }

        before do
          decorated_object.attendees.each do |attendee|
            allow(attendee).to receive(:response_status).
                                 and_return(CalendarAssistant::Event::RealResponse::DECLINED)
          end
        end

        it { is_expected.to_not be_abandoned }
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
        let(:decorated_object) { decorated_class.new(transparency: CalendarAssistant::Event::Transparency::TRANSPARENT) }

        it { is_expected.not_to be_busy }
      end

      context "event is opaque" do
        context "explicitly" do
          let(:decorated_object) { decorated_class.new(transparency: CalendarAssistant::Event::Transparency::OPAQUE) }

          it { is_expected.to be_busy }
        end

        context "implicitly" do
          let(:decorated_object) { decorated_class.new(transparency: CalendarAssistant::Event::Transparency::OPAQUE) }

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

        (CalendarAssistant::Event::RealResponse.constants - [:DECLINED]).each do |response_status_name|
          context "response is #{response_status_name}" do
            before do
              allow(attendee_self).to receive(:response_status).
                                        and_return(CalendarAssistant::Event::Response.const_get(response_status_name))
            end

            it { is_expected.to be_commitment }
          end
        end

        context "response status DECLINED" do
          before do
            allow(attendee_self).to receive(:response_status).
                                      and_return(CalendarAssistant::Event::Response::DECLINED)
          end

          it { is_expected.not_to be_commitment }
        end
      end
    end

    describe "#public?" do
      context "visibility is private" do
        let(:decorated_object) { decorated_class.new(visibility: CalendarAssistant::Event::Visibility::PRIVATE) }
        it { is_expected.not_to be_public }
      end

      context "visibility is nil" do
        it { is_expected.not_to be_public }
      end

      context "visibility is default" do
        let(:decorated_object) { decorated_class.new(visibility: CalendarAssistant::Event::Visibility::DEFAULT) }
        it { is_expected.not_to be_public }
      end

      context "visibility is public" do
        let(:decorated_object) { decorated_class.new(visibility: CalendarAssistant::Event::Visibility::PUBLIC) }

        it { is_expected.to be_public }
      end
    end

    describe "#recurring?" do
      context "when the meeting has a recurring id" do
        let(:decorated_object) { decorated_class.new(recurring_event_id: "12345") }
        it { is_expected.to be_recurring }
      end

      context "when the meeting does not have a recurring id" do
        let(:decorated_object) { decorated_class.new() }
        it { is_expected.not_to be_recurring }
      end
    end

    describe "#private?" do
      context "visibility is private" do
        let(:decorated_object) { decorated_class.new(visibility: CalendarAssistant::Event::Visibility::PRIVATE) }
        it { is_expected.to be_private }
      end

      context "visibility is nil" do
        it { is_expected.not_to be_private }
      end

      context "visibility is default" do
        let(:decorated_object) { decorated_class.new(visibility: CalendarAssistant::Event::Visibility::DEFAULT) }
        it { is_expected.not_to be_private }
      end

      context "visibility is public" do
        let(:decorated_object) { decorated_class.new(visibility: CalendarAssistant::Event::Visibility::PUBLIC) }
        it { is_expected.not_to be_private }
      end
    end

    describe "#explicitly_visible?" do
      context "when visibility is private" do
        let(:decorated_object) { decorated_class.new(visibility: CalendarAssistant::Event::Visibility::PRIVATE) }
        it { is_expected.to be_explicitly_visible }
      end

      context "when visibility is public" do
        let(:decorated_object) { decorated_class.new(visibility: CalendarAssistant::Event::Visibility::PUBLIC) }
        it { is_expected.to be_explicitly_visible }
      end

      context "when visibility is default" do
        let(:decorated_object) { decorated_class.new(visibility: CalendarAssistant::Event::Visibility::DEFAULT) }
        it { is_expected.not_to be_explicitly_visible }
      end

      context "when visibility is nil" do
        let(:decorated_object) { decorated_class.new(visibility: nil) }
        it { is_expected.not_to be_explicitly_visible }
      end
    end

    describe "#visible_guestlist?" do
      context "is true" do
        before { allow(subject).to receive(:guests_can_see_other_guests?).and_return(true) }

        it { is_expected.to be_visible_guestlist }
      end

      context "is false" do
        before { allow(subject).to receive(:guests_can_see_other_guests?).and_return(false) }

        it { is_expected.to_not be_visible_guestlist }
      end

      context "by default" do
        it { is_expected.to be_visible_guestlist }
      end
    end

    describe "#other_human_attendees" do
      context "there are no attendees" do
        it { expect(subject.human_attendees).to be_nil }
      end

      context "there are attendees including people and rooms" do
        let(:decorated_object) { decorated_class.new(attendees: attendees) }

        it "removes room resources from the list of attendees and myself" do
          expect(subject.other_human_attendees).to eq(attendees - [attendee_room_resource, attendee_self])
        end
      end
    end

    describe "#human_attendees" do
      context "there are no attendees" do
        it { expect(subject.human_attendees).to be_nil }
      end

      context "there are attendees including people and rooms" do
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

      context "there are attendees" do
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
        it { expect(subject.response_status).to eq(CalendarAssistant::Event::Response::SELF) }
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
end
