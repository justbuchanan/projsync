# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'projsync/version'

Gem::Specification.new do |spec|
  spec.name          = "projsync"
  spec.version       = Projsync::VERSION
  spec.authors       = ["Justin Buchanan"]
  spec.email         = ["justbuchanan@gmail.com"]
  spec.description   = %q{Sync all of your git repos with one command}
  spec.summary       = %q{Sync your projects}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency 'grit'
  spec.add_runtime_dependency 'trollop'
  spec.add_runtime_dependency 'colorize'
end
