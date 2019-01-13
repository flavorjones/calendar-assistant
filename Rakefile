#require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "concourse"
require "license_finder"

Concourse.new("calendar-assistant").create_tasks!

RSpec::Core::RakeTask.new(:test)

RSpec::Core::RakeTask.new(:spec)  do |t|
  t.rspec_opts ||= []
  t.rspec_opts << " --tag=~type:aruba"
end

RSpec::Core::RakeTask.new(:features)  do |t|
  t.rspec_opts ||= []
  t.rspec_opts << " --tag=type:aruba"
end

desc "Ensure all dependencies meet license requirements."
task :license_finder do
  LicenseFinder::CLI::Main.start(["report"])
  LicenseFinder::CLI::Main.start([])
end

desc "Run specs, features and license finder"
task :default => [:test, :license_finder]
