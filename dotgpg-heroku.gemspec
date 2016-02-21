# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dotgpg/heroku/version'
require "English"

Gem::Specification.new do |spec|
  spec.name          = "dotgpg-heroku"
  spec.version       = Dotgpg::Heroku::VERSION
  spec.authors       = ["Jonathan Schatz"]
  spec.email         = ["jon@divisionbyzero.com"]

  spec.summary       = spec.description = "push and pull dotgpg settings to/from heroku"
  spec.homepage      = "https://github.com/vouch/dotgpg-heroku"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "factory_girl"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "heroku_san"

  spec.add_dependency "dotgpg-environment"
  spec.add_dependency "heroku_san"
  spec.add_dependency "railties", "~>4.0"

end
