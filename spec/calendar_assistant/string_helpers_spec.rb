describe CalendarAssistant::StringHelpers do
  describe ".find_uri_for_domain" do
    context "text is nil" do
      it "returns nil" do
        expect(subject.find_uri_for_domain(nil, "example.com")).to be_nil
      end
    end

    context "text does not contain a URI for the domain" do
      it "returns nil" do
        expect(subject.find_uri_for_domain("This\ncontains https://docs.ruby-lang.org/foo which doesn't match", "example.com")).to be_nil
      end
    end

    context "text contain URIs for the domain" do
      it "returns the first one found" do
        expect(subject.find_uri_for_domain("This\ncontains https://docs.example.com/foo which matches, as does https://docs.example.com/bar", "example.com")).to eq("https://docs.example.com/foo")
      end
    end
  end
end
