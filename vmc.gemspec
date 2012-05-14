# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cf/version"

Gem::Specification.new do |s|
  s.name        = "cf"
  s.version     = CF::VERSION
  s.authors     = ["Alex Suraci"]
  s.email       = ["asuraci@vmware.com"]
  s.homepage    = "http://cloudfoundry.com/"
  s.summary     = %q{
    Friendly command-line interface for Cloud Foundry.
  }
  s.executables = %w{cf}

  s.rubyforge_project = "cf"

  s.files         = %w{LICENSE Rakefile} + Dir.glob("{lib,plugins}/**/*")
  s.test_files    = Dir.glob("spec/**/*")
  s.require_paths = ["lib"]

  s.add_runtime_dependency "json_pure", "~> 1.6.5"
  s.add_runtime_dependency "interact", "~> 0.4.1"
  s.add_runtime_dependency "cfoundry", "~> 0.1.0"
  s.add_runtime_dependency "thor", "~> 0.14.6"
  s.add_runtime_dependency "manifests-vmc-plugin", "~> 0.1.0"
end
