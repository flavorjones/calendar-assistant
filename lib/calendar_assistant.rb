#
#  stdlib
#
require "yaml"
require "uri"
require "set"
require "fileutils"

#
#  gem dependencies
#
require "business_time"
require "chronic"
require "chronic_duration"
require "calendar_assistant/extensions/google_apis_extensions"
require "calendar_assistant/extensions/launchy_extensions"
require "toml-rb"
require "thor"
require "calendar_assistant/extensions/rainbow_extensions"
require "active_support"

#
#  CalendarAssistant and associated classes
#
require "calendar_assistant/calendar_assistant"

class CalendarAssistant
  require "calendar_assistant/version"
  require "calendar_assistant/config"
  require "calendar_assistant/string_helpers"
  require "calendar_assistant/date_helpers"
  require "calendar_assistant/has_duration"
  require "calendar_assistant/available_block"
  require "calendar_assistant/event"
  require "calendar_assistant/event_repository"
  require "calendar_assistant/event_repository_factory"
  require "calendar_assistant/event_set"
  require "calendar_assistant/scheduler"
  require "calendar_assistant/local_service"
  require "calendar_assistant/location_event_repository"
  require "calendar_assistant/lint_event_repository"
  require "calendar_assistant/predicate_collection"
  require "calendar_assistant/location_config_validator"
end
