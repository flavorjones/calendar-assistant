class CalendarAssistant
  module CLI
    class EventPresenter < SimpleDelegator
      EMOJI_WARN = "⚠"

      def description
        s = formatted_event_date
        s += rainbow.wrap(sprintf(" | %s", view_summary)).bold
        s += event_attributes unless private?
        s = rainbow.wrap(Rainbow.uncolor(s)).faint.strike if declined?
        s
      end

      private

      def event_attributes
        attributes = []

        attributes << "recurring" if recurring?
        attributes << "not-busy" unless busy?
        attributes << "self" if self?
        attributes << "1:1" if one_on_one?
        attributes << "awaiting" if awaiting?
        attributes << "tentative" if tentative?
        attributes << rainbow.wrap(sprintf(" %s abandoned %s ", EMOJI_WARN, EMOJI_WARN)).red.bold.inverse if abandoned?

        attributes << visibility if explicitly_visible?

        attributes.empty? ? "" : rainbow.wrap(sprintf(" (%s)", attributes.to_a.sort.join(", "))).italic
      end
      def rainbow
        @rainbow ||= Rainbow.global
      end

      def formatted_event_date
        date = sprintf("%-25.25s", event_date)

        date_ansi_codes = []
        date_ansi_codes << :bright if current?
        date_ansi_codes << :faint if past?

        date_ansi_codes.inject(rainbow.wrap(date)) {|text, ansi| text.send ansi}
      end

      def event_date
        if all_day?
          start_date = __getobj__.start_date
          end_date = __getobj__.end_date
          if (end_date - start_date) <= 1
            start.to_s
          else
            sprintf("%s - %s", start_date, end_date - 1.day)
          end
        else
          if start_date == end_date
            sprintf("%s - %s", start.date_time.strftime("%Y-%m-%d  %H:%M"),  __getobj__.end.date_time.strftime("%H:%M"))
          else
            sprintf("%s  -  %s", start.date_time.strftime("%Y-%m-%d %H:%M"), __getobj__.end.date_time.strftime("%Y-%m-%d %H:%M"))
          end
        end
      end
    end
  end
end
