require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'
RSpec::Core::RakeTask.new(:rspec) do |t|
  t.pattern = 'spec/pipl/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:it_rspec) do |t|
  t.pattern = 'spec/integration/**/*_spec.rb'
end

task test: :rspec
task it_test: :it_rspec
task default: :rspec

namespace :ci do
  task spec: %w(ci:setup:rspec rspec)
  task it_spec: %w(ci:setup:rspec it_rspec)
end