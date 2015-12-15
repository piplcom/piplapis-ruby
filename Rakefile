require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/pipl/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:it_spec) do |t|
  t.pattern = 'spec/integration/**/*_spec.rb'
end

task test: :spec
task it_test: :it_spec
task default: :spec