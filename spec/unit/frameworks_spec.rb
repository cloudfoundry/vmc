require 'spec_helper'
require 'tmpdir'

describe 'VMC::Cli::Framework' do

  before(:each) do
    VMC::Cli::Config.nozip = true
  end

  it 'should be able to detect a Java web app war' do
    app = spec_asset('java_web')
    framework = VMC::Cli::Framework.detect(app)
    framework =~ /Java Web/
  end

  it 'should be able to detect an exploded Java web app' do
    war_file = spec_asset('java_web/java_web.war')
    framework = Dir.mktmpdir {|dir|
      exploded_dir = File.join(dir, "java_web_exp")
      VMC::Cli::ZipUtil.unpack(war_file, exploded_dir)
      VMC::Cli::Framework.detect(exploded_dir)
    }
    framework.to_s.should include("Java Web")
  end

  it 'should be able to detect a Spring web app war' do
    app = spec_asset('spring')
    framework = VMC::Cli::Framework.detect(app)
    framework =~ /Spring/
  end

  it 'should be able to detect an exploded Spring web app' do
    war_file = spec_asset('spring/spring.war')
    framework = Dir.mktmpdir {|dir|
      exploded_dir = File.join(dir, "spring_exp")
      VMC::Cli::ZipUtil.unpack(war_file, exploded_dir)
      VMC::Cli::Framework.detect(exploded_dir)
    }
    framework.to_s.should include("Spring")
  end

  it 'should be able to detect a Lift web app war' do
    app = spec_asset('lift')
    framework = VMC::Cli::Framework.detect(app)
    framework =~ /Lift/
  end

  it 'should be able to detect an exploded Lift web app' do
    war_file = spec_asset('lift/lift.war')
    framework = Dir.mktmpdir {|dir|
      exploded_dir = File.join(dir, "lift_exp")
      VMC::Cli::ZipUtil.unpack(war_file, exploded_dir)
      VMC::Cli::Framework.detect(exploded_dir)
    }
    framework.to_s.should include("Lift")
  end

  it 'should be able to detect a Grails web app war' do
    app = spec_asset('grails')
    framework = VMC::Cli::Framework.detect(app)
    framework =~ /Grails/
  end

  it 'should be able to detect an exploded Grails web app' do
    war_file = spec_asset('grails/grails.war')
    framework = Dir.mktmpdir {|dir|
      exploded_dir = File.join(dir, "grails_exp")
      VMC::Cli::ZipUtil.unpack(war_file, exploded_dir)
      VMC::Cli::Framework.detect(exploded_dir)
    }
    framework.to_s.should include("Grails")
  end

  it 'should be able to detect a Rails3 app' do
    app = spec_asset('rails3')
    framework = VMC::Cli::Framework.detect(app)
    framework =~ /Rails/
  end

  it 'should be able to detect a Sinatra app' do
    app = spec_asset('sinatra')
    framework = VMC::Cli::Framework.detect(app)
    framework =~ /Sinatra/
  end
  it 'should be able to detect a Node.js app' do
    app = spec_asset('node')
    framework = VMC::Cli::Framework.detect(app)
    framework =~ /Node.js/
  end
  it 'should be able to detect a Erlang web app' do
    app = spec_asset('otp_rebar')
    framework = VMC::Cli::Framework.detect(app)
    framework =~ /Erlang/
  end

end