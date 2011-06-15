require 'bundler/gem_tasks'
require 'rake'
if !defined?(sh) && defined?(Rake::DSL)
  include Rake::DSL
end

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec
