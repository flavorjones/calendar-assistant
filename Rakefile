#require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "concourse"
require "license_finder"

Concourse.new("calendar-assistant").create_tasks!

RSpec::Core::RakeTask.new(:spec)

desc "Ensure all dependencies meet license requirements."
task :license_finder do
  LicenseFinder::CLI::Main.start(["report"])
  LicenseFinder::CLI::Main.start([])
end

desc "Run specs and license finder"
task :default => [:spec, :license_finder]
