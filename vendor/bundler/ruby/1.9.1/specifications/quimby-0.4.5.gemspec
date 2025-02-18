# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "quimby"
  s.version = "0.4.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Pat Nakajima"]
  s.date = "2011-01-14"
  s.email = "pat@groupme.com"
  s.homepage = "https://github.com/groupme/quimby"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "A Foursquare API wrapper"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<typhoeus>, [">= 0"])
      s.add_runtime_dependency(%q<json>, [">= 0"])
    else
      s.add_dependency(%q<typhoeus>, [">= 0"])
      s.add_dependency(%q<json>, [">= 0"])
    end
  else
    s.add_dependency(%q<typhoeus>, [">= 0"])
    s.add_dependency(%q<json>, [">= 0"])
  end
end
