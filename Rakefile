require "bundler/gem_tasks"
require "bundler/setup"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

require "standard/rake"

task default: %w[spec standard]
