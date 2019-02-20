class CalendarAssistant
  class LintEventRepository < EventRepository
    def find(time, predicates: {})
      super(time, predicates: predicates.merge({ needs_action?: true }))
    end
  end
end
