# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name = %q{ffmpeg}
  s.version = "0.2.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Patrik Hedman", "Lee Horrocks"]
  s.date = %q{2011-05-29}
  s.description = %q{A DSL for building and executing ffmpeg commands}
  s.email = %q{patrik@moresale.se}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.textile"
  ]
  s.homepage = %q{http://github.com/polly/ffmpeg}
  s.rdoc_options = ["--charset=UTF-8"]
  s.required_rubygems_version = ">= 1.6.0"
  s.summary = %q{A dsl for building and executing ffmpeg commands}
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_development_dependency("rake", "~> 0.8.7")
  s.add_development_dependency("bundler", "~> 1.0.0")
  s.add_development_dependency("jeweler", "~> 1.6.0")
  s.add_development_dependency("rspec", ">= 2.5.0")
  s.add_development_dependency("cucumber", ">= 0.10.0")
  s.add_development_dependency("rdoc", "~> 3.6")
end
