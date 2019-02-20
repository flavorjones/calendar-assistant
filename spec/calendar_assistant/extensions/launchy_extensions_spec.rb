require "calendar_assistant/extensions/launchy_extensions"

describe CalendarAssistant::ZoomLaunchy do
  describe "launchy extension" do
    it "our class needs to be first" do
      expect(Launchy::Application.children.first).to eq(described_class)
    end
  end

  describe ".handles?" do
    context "given a non-zoom url" do
      let(:url) { "https://schmoopie.org/foo/bar" }
      it { expect(described_class.handles?(url)).to be_falsey }
    end

    context "given a zoom url" do
      context "that is a personal link" do
        let(:url) { "https://schmoopie.zoom.us/my/flavorjones" }
        it { expect(described_class.handles?(url)).to be_falsey }
      end

      context "that is a conference number link" do
        let(:url) { "https://schmoopie.zoom.us/j/999999999" }
        it { expect(described_class.handles?(url)).to be_truthy }
      end
    end
  end

  describe "#open" do
    context "given a zoom conference number link" do
      before { ENV["BROWSER"] = "mybrowser" } # used by parent class Launchy::Application::Browser

      let(:url) { "https://schmoopie.zoom.us/j/999999999" }
      let(:zoommtg) { "zoommtg://zoom.us/join?confno=999999999" }

      [["darwin", "open"], ["linux", "xdg-open"]].each do |host_os, command|
        context "on host os '#{host_os}'" do
          around do |example|
            Launchy.host_os = host_os
            example.call
            Launchy.host_os = nil
          end

          context "executable '#{command}' is found" do
            before do
              allow(subject).to(receive(:find_executable).with(command).
                and_return("/path/to/#{command}"))
            end

            it "runs the executable '#{command}' with a transformed URL" do
              expect(subject).to(receive(:run).with("/path/to/#{command}", [zoommtg]))
              subject.open(url)
            end
          end

          context "executable '#{command}' is not found" do
            before do
              allow(subject).to(receive(:find_executable).with(command).
                and_return(nil))
            end

            it "runs the browser with the original URL" do
              expect(subject).to(receive(:run).with("mybrowser", [url]))
              subject.open(url)
            end
          end
        end
      end
    end
  end
end
