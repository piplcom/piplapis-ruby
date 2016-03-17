require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'
RSpec::Core::RakeTask.new(:rspec)

task test: :rspec
task default: :rspec

namespace :ci do
  task spec: %w(ci:setup:rspec rspec)
end