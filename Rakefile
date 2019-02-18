#require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "concourse"
require "license_finder"
require "tempfile"
require "rainbow"

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
RSpec::Core::RakeTask.new("spec:unit") do |t|
  t.rspec_opts ||= []
  t.rspec_opts << " --tag=~type:aruba"
end

desc "Run feature specs"
RSpec::Core::RakeTask.new("spec:feature") do |t|
  t.rspec_opts ||= []
  t.rspec_opts << " --tag=type:aruba"
end

desc "Ensure all dependencies meet license requirements"
task "license_finder" do
  LicenseFinder::CLI::Main.start(["report"])
  LicenseFinder::CLI::Main.start([])
end

#
#  readme tasks
#
desc "Generate the README.md from its erb template"
task "readme" do
  sh "./generate-readme"
end

desc "Generate the README.md from its erb template"
task "readme:check" do
  file = Tempfile.new("readme").path
  sh "./generate-readme #{file}"
  sh "diff -C3 #{file} README.md"
  puts Rainbow("README.md looks good").green
end

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

#
#  formatting
#
desc "Format ruby code"
task "format" do
  sh "rufo lib spec", verbose: true
end

#
#  default
#
desc "Run unit specs, feature specs, license finder, and check the README"
task "default" => ["spec", "license_finder", "readme:check"]
