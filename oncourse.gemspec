# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'oncourse/version'

Gem::Specification.new do |spec|
  spec.name          = "oncourse"
  spec.version       = Oncourse::VERSION
  spec.authors       = ["steve"]
  spec.email         = ["stevecd123@gmail.com"]
  spec.summary       = %q{A gem to make some tedious oncourse tasks less tedious.}
  spec.description   = %q{oncoursesystems.com's interface is very tedious to work with for certain cases and this gem seeks to automate some of it.}
  spec.homepage      = "https://github.com/stevecd/ruby-oncourse"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
