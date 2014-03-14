# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'oncourse/version'

Gem::Specification.new do |spec|
  spec.name          = "oncourse"
  spec.version       = Oncourse::VERSION
  spec.authors       = ["steve"]
  spec.email         = ["stevecd123@gmail.com"]
  spec.summary       = %q{Provides a basic lessonplan API}
  spec.description   = %q{oncoursesystems.com's interface is very tedious to work with in a lot of cases, this gem uses mechanize to scrape and post lessonplan data}
  spec.homepage      = "https://github.com/stevecd/ruby-oncourse"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  
  spec.add_runtime_dependency "mechanize"
end
