#
#  stdlib
#
autoload :YAML, "yaml"
autoload :URI, "uri"
autoload :Set, "set"
autoload :FileUtils, "fileutils"

#
#  gem dependencies
#
autoload :BusinessTime, "business_time"
autoload :Chronic, "chronic"
autoload :ChronicDuration, "chronic_duration"
autoload :Google, "calendar_assistant/extensions/google_apis_extensions"
autoload :Launchy, "launchy"
autoload :TOML, "toml"
autoload :Thor, "thor"
require "calendar_assistant/extensions/rainbow_extensions" # Rainbow() doesn't trigger autoload

#
#  CalendarAssistant and associated classes
#
require "calendar_assistant/calendar_assistant"

class CalendarAssistant
  autoload :VERSION,                "calendar_assistant/version"
  autoload :Config,                 "calendar_assistant/config"
  autoload :Authorizer,             "calendar_assistant/authorizer"
  autoload :StringHelpers,          "calendar_assistant/string_helpers"
  autoload :DateHelpers,            "calendar_assistant/date_helpers"
  autoload :Event,                  "calendar_assistant/event"
  autoload :EventRepository,        "calendar_assistant/event_repository"
  autoload :EventRepositoryFactory, "calendar_assistant/event_repository_factory"
  autoload :EventSet,               "calendar_assistant/event_set"
  autoload :Scheduler,              "calendar_assistant/scheduler"
  autoload :LocalService,           "calendar_assistant/local_service"
end

require "calendar_assistant/cli"
