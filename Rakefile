require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "freyr"
    gem.summary = %Q{Service manager and runner}
    gem.description = %Q{Define all services you need to run and this will launch,daemonize,and monitor them for you.}
    gem.email = "me@tal.by"
    gem.homepage = "http://github.com/Talby/freyr"
    gem.authors = ["Tal Atlas"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "yard", ">= 0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
    gem.add_dependency 'thor', ">= 0.10"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

begin
  require 'spec/rake/spectask'
  Spec::Rake::SpecTask.new(:spec) do |spec|
    spec.libs << 'lib' << 'spec'
    spec.spec_files = FileList['spec/**/*_spec.rb']
  end
  
  
  Spec::Rake::SpecTask.new(:rcov) do |spec|
    spec.libs << 'lib' << 'spec'
    spec.pattern = 'spec/**/*_spec.rb'
    spec.rcov = true
  end
  
  task :spec => :check_dependencies
  
  task :default => :spec
rescue LoadError
  puts "Expecting rspec to be installed. Please install with: gem install rspec"
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end
