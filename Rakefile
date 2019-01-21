#require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "concourse"
require "license_finder"

#
#  concourse
#
Concourse.new("calendar-assistant", fly_target: "calendar-assistants").create_tasks!


#
#  spec tasks
#
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


#
# docker docker docker
#
desc "Build a docker image for testing"
task "docker:build" do
  sh "docker build -t flavorjones/calendar-assistant-test -f concourse/images/Dockerfile ."
end

desc "Push a docker image for testing"
task "docker:push" do
  sh "docker push flavorjones/calendar-assistant-test"
end

desc "Build and push a docker image for testing"
task "docker" => ["docker:build", "docker:push"]
