
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "calendar_assistant/version"

Gem::Specification.new do |spec|
  spec.name          = "calendar_assistant"
  spec.version       = CalendarAssistant::VERSION
  spec.authors       = ["Mike Dalessio"]
  spec.email         = ["mike.dalessio@gmail.com"]

  spec.summary       = %q{A command-line tool to help manage your Google Calendar.}
  spec.description   = %q{A command-line tool to help manage your Google Calendar.}
  spec.homepage      = "https://github.com/flavorjones/calendar-assistant"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z lib bin Gemfile LICENSE NOTICE README.md Rakefile`.split("\x0")
  end

  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "google-api-client"
  spec.add_dependency "chronic"
  spec.add_dependency "chronic_duration"
  spec.add_dependency "thor"
  spec.add_dependency "business_time"
  spec.add_dependency "rainbow"
  spec.add_dependency "launchy"
  spec.add_dependency "toml"

  spec.add_development_dependency "concourse"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "timecop"

  # optional, natch
  spec.add_development_dependency "autotest"
  spec.add_development_dependency "rspec-autotest"
  spec.add_development_dependency "test_notifier"
end
