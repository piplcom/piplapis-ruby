require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'
RSpec::Core::RakeTask.new(:spec)

task test: :spec
task default: :spec

namespace :ci do
  task spec: %w(ci:setup:rspec spec)
end