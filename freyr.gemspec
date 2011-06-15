# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "freyr/version"

Gem::Specification.new do |s|
  s.name        = "freyr"
  s.version     = Freyr::VERSION
  s.authors     = ["Tal Atlas"]
  s.email = %q{me@tal.by}
  s.homepage = %q{http://github.com/Talby/freyr}
  
  s.description = %q{Define all services you need to run and this will launch,daemonize,and monitor them for you.}
  s.summary = %q{Service manager and runner}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.default_executable = %q{freyr}
  s.require_paths = ["lib"]

  s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
  s.add_development_dependency(%q<yard>, [">= 0"])
  s.add_runtime_dependency(%q<thor>, [">= 0.10"])
end
