describe CalendarAssistant::CLI::Repl do
  class FakeReadLine
    def initialize(inputs)
      @inputs = Array(inputs)
    end

    def readline(*args)
      return nil if @inputs.empty?
      @inputs.pop
    end
  end

  describe CalendarAssistant::CLI::Repl::History do
    with_temp_file("history")

    it "persists the history" do
      readline_history = ["command 1", "command 2"]
      history = described_class.new(readline_history: readline_history, history_file_path: temp_file.path)
      history.write_history
      expect(File.open(temp_file.path).readlines.map(&:chomp)).to match_array readline_history
    end

    it "reads the history" do
      readline_history = []
      File.open(temp_file.path, "w") do |f|
        f.puts "seal team six"
        f.puts "funky cold medina"
      end

      history = described_class.new(readline_history: readline_history, history_file_path: temp_file.path)
      history.read_history
      expect(readline_history).to match_array ["seal team six", "funky cold medina"]
    end
  end

  describe "instance methods" do
    let(:thor_class) { double(:thor_class) }
    let(:readline_class) { FakeReadLine.new(input) }
    let(:repl) { described_class.new(thor_class, readline_class: readline_class, welcome_message: false) }

    describe "#with_history" do
      let(:history) { double(:history) }
      let(:input) { "exit" }

      it "reads and writes history" do
        expect(history).to receive(:read_history)
        expect(history).to receive(:write_history)
        repl.with_history(history)
      end
    end

    describe "#with_no_history" do
      context "when input is exit" do
        let(:input) { "exit" }

        it "breaks without calling through" do
          expect(thor_class).not_to receive(:start)

          repl.with_no_history
        end
      end

      context "when input is exit!" do
        let(:input) { "exit!" }

        it "breaks without calling through" do
          expect(thor_class).not_to receive(:start)

          repl.with_no_history
        end
      end

      context "when input is something else" do
        let(:input) { "command --arg1=value" }

        it "it calls through" do
          expect(thor_class).to receive(:start).with(["command", "--arg1=value"])

          repl.with_no_history
        end
      end
    end
  end
end
