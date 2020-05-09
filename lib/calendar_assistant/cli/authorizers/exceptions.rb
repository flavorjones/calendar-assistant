class CalendarAssistant
  module CLI
    module Authorizers
      class NoCredentials < CalendarAssistant::BaseException; end
      class UnauthorizedError < CalendarAssistant::BaseException; end
    end
  end
end
