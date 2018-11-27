describe EventFactory do
  freeze_time

  let(:event_factory) { EventFactory.new }
  let(:default_attributes) { { } }

  describe "#for" do
    let(:events) { event_factory.for(default_attributes) { attributes } }

    describe "id" do
      subject { events.first.id }

      describe "when an id is passed" do
        let(:attributes) { { id: "fancy-id" } }

        it { is_expected.to eq "fancy-id" }
      end

      describe "when an id is not passed" do
        let(:attributes) { { } }

        it { is_expected.to be }
        it { is_expected.not_to eq "fancy-id" }
      end
    end

    describe "dates" do
      subject { events.first }

      let(:attributes) { { start: "10:00", end: "15:00" } }

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

      describe "options" do
        shared_examples_for "an option that translates to a predicate" do
          context "when the option is set" do
            let(:attributes) { { start: Time.now.to_s, options: [ option ] } }
            it { is_expected.to self.send("be_#{option}") }
          end

          context "when the option is not set" do
            let(:attributes) { { start: Time.now.to_s, options: [] } }
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

        describe "location event" do
          it_behaves_like "an option that translates to a predicate" do
            let(:option) { :location_event }
          end

          describe "not self and not one_on_one" do
            let(:attributes) { { } }
            it "should have more than 2 attendees" do
              expect(subject.attendees.length).to be > 2
            end
          end
        end
      end
    end
  end
end
