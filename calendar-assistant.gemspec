
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "calendar_assistant/version"

Gem::Specification.new do |spec|
  spec.name = "calendar-assistant"
  spec.version = CalendarAssistant::VERSION
  spec.authors = ["Mike Dalessio", "Mik Freedman"]
  spec.email = ["mike.dalessio@gmail.com", "github@michael-freedman.com"]

  spec.summary = %q{A command-line tool to help manage your Google Calendar.}
  spec.description = %q{A command-line tool to help manage your Google Calendar.}
  spec.homepage = "https://github.com/flavorjones/calendar-assistant"
  spec.license = "Apache-2.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  if Dir.exist?(".git")
    spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
      `git ls-files -z lib bin Gemfile LICENSE NOTICE README.md Rakefile`.split("\x0")
    end
  end

  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 5.2.1", "< 6.1.0"
  spec.add_dependency "business_time", ">= 0.9", "< 0.11"
  spec.add_dependency "chronic", "~> 0.10.0"
  spec.add_dependency "chronic_duration", "~> 0.10.0"
  spec.add_dependency "google-api-client", ">= 0.24", "< 0.54"
  spec.add_dependency "launchy", "~> 2.4"
  spec.add_dependency "rainbow", "~> 3.0"
  spec.add_dependency "thor", ">= 0.20", "< 1.2"
  spec.add_dependency "toml", "~> 0.2.0"
  spec.add_dependency "thor_repl", "~> 0.1.4"

  spec.add_development_dependency "aruba", "~> 1.0.0"
  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "concourse"
  spec.add_development_dependency "faker", "~> 2.1"
  spec.add_development_dependency "license_finder", "~> 6.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "timecop", "~> 0.9"
  spec.add_development_dependency "simplecov", "~> 0.21"
end
