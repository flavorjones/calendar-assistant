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
desc "Run unit and feature specs"
RSpec::Core::RakeTask.new("spec")
task "test" => "spec" # undocumented alias for 'spec'

desc "Run unit specs"
RSpec::Core::RakeTask.new("spec:unit")  do |t|
  t.rspec_opts ||= []
  t.rspec_opts << " --tag=~type:aruba"
end

desc "Run feature specs"
RSpec::Core::RakeTask.new("spec:feature")  do |t|
  t.rspec_opts ||= []
  t.rspec_opts << " --tag=type:aruba"
end

desc "Ensure all dependencies meet license requirements."
task "license_finder" do
  LicenseFinder::CLI::Main.start(["report"])
  LicenseFinder::CLI::Main.start([])
end

desc "Run unit specs, feature specs, and license finder"
task "default" => ["spec", "license_finder"]


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
