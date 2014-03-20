# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = 'matchete'
  s.version     = '0.0.1'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Alexander Ivanov"]
  s.email       = ["alehander42@gmail.com"]
  s.homepage = 'https://github.com/alehander42/matchete'
  s.summary     = %q{Method overloading for Ruby based on pattern matching}
  s.description = %q{A DSL for method overloading for Ruby based on pattern matching}

  s.add_development_dependency 'rspec', '~> 0'
  
  s.license       = 'MIT'
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end