describe EventFactory do
  freeze_time
  let(:event_factory) { EventFactory.new }

  describe "#for_in_hash" do
    it "retains the original structure" do
      events = event_factory.create_list do
        {
          "key 1" => [{ id: "funky" }],
          "key 2" => [{ id: "cold" }, { id: "medina" }],
        }
      end

      expect(events.keys).to match_array(["key 1", "key 2"])
      expect(events["key 2"].map(&:id)).to match_array(["cold", "medina"])
    end
  end

  describe "#create_list" do
    let(:default_attributes) { {} }

    describe "passing attributes as a block" do
      context "when no block is passed" do
        it "raises an ArgumentError" do
          expect { event_factory.create_list(**default_attributes) }.to raise_error(ArgumentError)
        end
      end

      context "when a block is passed" do
        it "does not raise an ArgumentError" do
          expect { event_factory.create_list(**default_attributes) { [] } }.not_to raise_error
        end
      end
    end

    subject { event_factory.create_list(**default_attributes) { [attributes] }.first }
    let(:attributes) { { start: "10:00", end: "15:00" } }

    describe "date parsing" do
      describe "when a default date is set" do
        let(:default_attributes) { { date: "2001-01-01" } }

        it "parses the start and end dates relative to that date" do
          expect(subject.start.date_time).to eq Chronic.parse("2001-01-01 10:00")
          expect(subject.end.date_time).to eq Chronic.parse("2001-01-01 15:00")
        end
      end

      describe "when a default date is not set" do
        it "parses the start and end dates relative to now" do
          expect(subject.start.date_time).to eq Chronic.parse("2018-07-13 10:00")
          expect(subject.end.date_time).to eq Chronic.parse("2018-07-13 15:00")
        end
      end
    end
  end

  describe "#create" do
    let(:event) { event_factory.create(event_attributes: attributes) }

    describe "id" do
      subject { event.id }

      describe "when an id is passed" do
        let(:attributes) { { id: "fancy-id" } }

        it { is_expected.to eq "fancy-id" }
      end

      describe "when an id is not passed" do
        let(:attributes) { {} }

        it { is_expected.to be }
        it { is_expected.not_to eq "fancy-id" }
      end
    end

    describe "dates" do
      subject { event }

      let(:attributes) { { start: "10:00", end: "15:00" } }

      describe "options" do
        describe "passing multiple options" do
          let(:attributes) { { start: Time.now.to_s, options: [:recurring, :self] } }

          it { is_expected.to be_recurring }
          it { is_expected.to be_self }
        end

        describe "individual options" do
          shared_examples_for "an option that translates to a predicate" do
            context "when the option is set" do
              let(:attributes) { { start: Time.now.to_s, options: option } }
              it { is_expected.to self.send("be_#{option}") }
            end

            context "when the option is not set" do
              let(:attributes) { { start: Time.now.to_s } }
              it { is_expected.not_to self.send("be_#{option}") }
            end
          end

          describe "recurring" do
            it_behaves_like "an option that translates to a predicate" do
              let(:option) { :recurring }
            end
          end

          describe "self" do
            it_behaves_like "an option that translates to a predicate" do
              let(:option) { :self }
            end
          end

          describe "one_on_one" do
            it_behaves_like "an option that translates to a predicate" do
              let(:option) { :one_on_one }
            end
          end

          describe "declined" do
            it_behaves_like "an option that translates to a predicate" do
              let(:option) { :declined }
            end
          end

          describe "accepted" do
            it_behaves_like "an option that translates to a predicate" do
              let(:option) { :accepted }
            end
          end

          describe "needs_action" do
            it_behaves_like "an option that translates to a predicate" do
              let(:option) { :needs_action }
            end
          end

          describe "tentative" do
            it_behaves_like "an option that translates to a predicate" do
              let(:option) { :tentative }
            end
          end

          describe "private" do
            it_behaves_like "an option that translates to a predicate" do
              let(:option) { :private }
            end
          end

          describe "busy" do
            context "when set" do
              let(:attributes) { { start: Time.now.to_s, options: :busy } }
              it { is_expected.to be_busy }
            end

            context "when deliberately not set" do
              let(:attributes) { { start: Time.now.to_s } }
              it { is_expected.to be_busy }
            end

            context "when set to free" do
              let(:attributes) { { start: Time.now.to_s, options: :free } }
              it { is_expected.not_to be_busy }
            end
          end

          describe "location event" do
            let(:option) { :location_event }
            let(:attributes) { { start: Time.now.to_s, options: option } }

            it_behaves_like "an option that translates to a predicate"

            it { is_expected.to_not be_busy }

            it "has only one attendee, the self" do
              expect(subject.attendees.length).to eq 1
              expect(subject.attendees[0].self).to be_truthy
            end
          end

          describe "not self and not one_on_one" do
            let(:attributes) { {} }
            it "should have more than 2 attendees" do
              expect(subject.attendees.length).to be > 2
            end
          end
        end
      end
    end
  end
end
