class CalendarAssistant
  module CLI
    class LinterEventPresenter < EventPresenter
      EMOJI_ACCEPTED = "👍"
      EMOJI_DECLINED = "👎"
      EMOJI_NEEDS_ACTION = "🤷"
      SUMMARY_THRESHOLD = 5

      def description
        s = formatted_event_date
        date_length = s.length
        s += rainbow.wrap(sprintf(" | %s", view_summary)).bold
        s += event_attributes unless private?
        s = rainbow.wrap(Rainbow.uncolor(s)).faint.strike if declined?
        s += "\n #{' ' * (date_length + 2)}attendees: #{attendees}"
        s
      end

      def attendees
        if required_other_attendees .length > SUMMARY_THRESHOLD
          summary_attendee_list
        else
          detailed_attendee_list
        end
      end

      private

      def detailed_attendee_list
        required_other_attendees.map do |attendee|
          sprintf "%s %s", response_emoji(attendee.response_status), attendee.email || "<no email>"
        end.join(", ")
      end

      def summary_attendee_list
        summary = required_other_attendees.group_by do |attendee|
          response_emoji(attendee.response_status)
        end

        summary.sort.map do |emoji, attendees|
          "#{emoji} - #{attendees.count}"
        end.join(", ")
      end

      def required_other_attendees
        @required_other_attendees ||= (other_human_attendees || []).select {|a| !a.optional }
      end

      def response_emoji(response_status)
        return EMOJI_ACCEPTED if response_status == CalendarAssistant::Event::Response::ACCEPTED
        return EMOJI_DECLINED if response_status == CalendarAssistant::Event::Response::DECLINED
        return EMOJI_NEEDS_ACTION
      end
    end
  end
end
