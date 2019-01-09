class CalendarAssistant
  module CLI
    class EventPresenter < SimpleDelegator
      EMOJI_WARN = "⚠"

      def description
        s = sprintf("%-25.25s", event_date_description)

        date_ansi_codes = []
        date_ansi_codes << :bright if current?
        date_ansi_codes << :faint if past?

        s = date_ansi_codes.inject(rainbow.wrap(s)) {|text, ansi| text.send ansi}

        s += rainbow.wrap(sprintf(" | %s", view_summary)).bold

        unless private?
        attributes = []
          attributes << "recurring" if recurring?
          attributes << "not-busy" unless busy?
          attributes << "self" if self?
          attributes << "1:1" if one_on_one?
          attributes << "awaiting" if awaiting?
          attributes << "tentative" if tentative?
          attributes << rainbow.wrap(sprintf(" %s abandoned %s ", EMOJI_WARN, EMOJI_WARN)).red.bold.inverse if abandoned?

          attributes << visibility if explicitly_visible?
        end

        s += rainbow.wrap(sprintf(" (%s)", attributes.to_a.sort.join(", "))).italic unless attributes.empty?

        s = rainbow.wrap(Rainbow.uncolor(s)).faint.strike if declined?

        s
      end

      private

      def rainbow
        @rainbow ||= Rainbow.global
      end

      def event_date_description
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
