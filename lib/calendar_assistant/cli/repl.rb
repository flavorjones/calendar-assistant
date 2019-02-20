require "readline"

class CalendarAssistant
  module CLI
    class Repl
      class History
        HISTORY_FILE_PATH = File.join (ENV["CA_HOME"] || ENV["HOME"]), ".calendar-assistant.history"

        attr_reader :history_file

        def initialize(readline_history: Readline::HISTORY, history_file_path: HISTORY_FILE_PATH)
          @readline_history = readline_history
          @history_file = history_file_path && File.expand_path(history_file_path)
        end

        def read_history
          if history_file && File.exists?(history_file)
            IO.readlines(history_file).each { |e| @readline_history << e.chomp }
          end
        end

        def write_history
          if history_file
            File.open(history_file, "w") { |f| f.puts(*Array(@readline_history)) }
          end
        end
      end

      def self.start(thor_command_class, history = true)
        instance = self.new(thor_command_class)

        if history
          instance.with_history
        else
          instance.with_no_history
        end
      end

      def initialize(thor_commands_class, readline_class: Readline, welcome_message: true)
        @welcome_message = welcome_message
        @readline_class = readline_class
        @thor_commands_class = thor_commands_class
      end

      def with_history(history = History.new)
        history.read_history
        with_no_history
      ensure
        history.write_history
      end

      def with_no_history
        puts "Welcome to interactive mode. Use 'help' to list available commands" if @welcome_message

        repl(-> () { @readline_class.readline("> ", true) }) do |input|
          args = input.split("\s")
          @thor_commands_class.start(args)
        end
      end

      private

      def repl(input_proc)
        while (input = input_proc.call)
          case input
          when /^exit!?/
            break
          when //
            Readline::HISTORY.pop
          end

          yield(input) if block_given?
        end
      end
    end
  end
end
