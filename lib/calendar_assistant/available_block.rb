class CalendarAssistant
  class AvailableBlock
    include HasDuration

    attr_reader :start, :end

    def initialize(**params)
      @start = HasDuration.cast_datetime(params[:start]) if params[:start]
      @end = HasDuration.cast_datetime(params[:end]) if params[:end]
    end
  end
end