# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "kindlerb"

Gem::Specification.new do |s|
  s.name        = "kindlerb"
  s.version     = Kindlerb::VERSION
  s.platform    = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.9.0'

  s.authors     = ["Daniel Choi"]
  s.email       = ["dhchoi@gmail.com"]
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
