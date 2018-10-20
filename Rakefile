#require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "concourse"

Concourse.new("calendar-assistant").create_tasks!

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
