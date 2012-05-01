$:.unshift('./lib')
require 'bundler'
require 'bundler/setup'
require 'vmc'
require 'vmc/cli'

require 'rspec'
require 'webmock/rspec'

def spec_asset(filename)
  File.expand_path(File.join(File.dirname(__FILE__), "assets", filename))
end
