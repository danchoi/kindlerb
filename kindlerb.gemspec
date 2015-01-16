# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "kindlerb"
  s.version     = '0.2'
  s.platform    = Gem::Platform::RUBY
  s.required_ruby_version = '>= 2.0.0'

  s.authors     = ["Daniel Choi", "Emir Aydin"]
  s.email       = ["dhchoi@gmail.com", "emir@emiraydin.com"]
  s.homepage    = "http://github.com/danchoi/kindlerb"
  s.summary     = %q{Kindle eperiodical generator}
  s.description = %q{Kindle eperiodical generator}

  s.rubyforge_project = "kindlerb"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'nokogiri'
  s.add_dependency 'mustache'
end
