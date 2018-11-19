#
#  this file extends the Google::Event class found in the "google_calendar" rubygem
#

require "google/apis/calendar_v3"
require "time"
require "calendar_assistant/extensions/event_date_time_extensions"

class Google::Apis::CalendarV3::Event
  module RealResponse
    DECLINED = "declined"
    ACCEPTED = "accepted"
    NEEDS_ACTION = "needsAction"
    TENTATIVE = "tentative"
  end

  module Response
    include RealResponse
    SELF = "self" # not part of Google's API, but useful to represent meetings-for-myself
  end

  module Transparency
    TRANSPARENT = "transparent"
    OPAQUE = "opaque"
  end

  module Visibility
    DEFAULT = "default"
    PUBLIC = "public"
    PRIVATE = "private"
  end
end
