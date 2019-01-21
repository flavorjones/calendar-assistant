describe CalendarAssistant::PredicateCollection do
  let(:true_predicates) { [:one, "two"] }
  let(:false_predicates){ [:three, :four] }

  it "adds predicates that are true and false, and makes em look like predicate methods" do
    result = described_class.build(true_predicates, false_predicates)
    expect(result[:one?]).to be_truthy
    expect(result[:two?]).to be_truthy
    expect(result[:three]).to be_falsey
    expect(result[:four]).to be_falsey
  end
end