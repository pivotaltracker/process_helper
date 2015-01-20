# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'process_helper/version'

Gem::Specification.new do |spec|
  spec.name          = "process_helper"
  spec.version       = ProcessHelper::VERSION
  spec.authors       = ["Glenn Oppegard", "Chad Woolley"]
  spec.email         = ["oppegard@gmail.com", "thewoolleyman@gmail.com"]
  spec.summary       = %q{Makes it easier to spawn ruby sub-processes with proper capturing of stdout and stderr streams.}
  spec.description   = %q{Wrapper around Open3#popen2e with other useful options.}
  spec.homepage      = "https://github.com/oppegard/process_helper"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 1.9.2"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10"
  spec.add_development_dependency "rspec", "~> 3.1"
end