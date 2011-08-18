require 'spec_helper'
require 'tmpdir'

describe 'VMC::Client::Framework' do

  it 'should report its frameworks' do
    frameworks = VMC::Cli::Framework.known_frameworks
    frameworks.should_not == nil
  end

  it 'should be able to detect a Java web app war' do
    app = spec_asset('java_web')
    framework = VMC::Cli::Framework.detect(app)
    framework =~ /Java Web/
  end

  it 'should be able to detect an exploded Java web app' do
    app = spec_asset('java_web/java_web.war')
    exploded_dir = File.join(Dir.tmpdir, "java_web_exp")
    Kernel.`("unzip #{app} -d #{exploded_dir}")
    framework = VMC::Cli::Framework.detect(exploded_dir)
    Kernel.`("rm -rf #{exploded_dir}")
    framework =~ /Java Web/
  end

  it 'should be able to detect a Spring web app war' do
    app = spec_asset('spring')
    framework = VMC::Cli::Framework.detect(app)
    framework =~ /Spring/
  end

  it 'should be able to detect an exploded Spring web app' do
    app = spec_asset('spring/spring.war')
    exploded_dir = File.join(Dir.tmpdir, "spring_exp")
    Kernel.`("unzip #{app} -d #{exploded_dir}")
    framework = VMC::Cli::Framework.detect(exploded_dir)
    Kernel.`("rm -rf #{exploded_dir}")
    framework =~ /Spring/
  end

  it 'should be able to detect a Lift web app war' do
    app = spec_asset('lift')
    framework = VMC::Cli::Framework.detect(app)
    framework =~ /Lift/
  end

  it 'should be able to detect an exploded Lift web app' do
    app = spec_asset('lift/lift.war')
    exploded_dir = File.join(Dir.tmpdir, "lift_exp")
    Kernel.`("unzip #{app} -d #{exploded_dir}")
    framework = VMC::Cli::Framework.detect(exploded_dir)
    Kernel.`("rm -rf #{exploded_dir}")
    framework =~ /Lift/
  end

  it 'should be able to detect a Grails web app war' do
    app = spec_asset('grails')
    framework = VMC::Cli::Framework.detect(app)
    framework =~ /Grails/
  end

  it 'should be able to detect an exploded Grails web app' do
    app = spec_asset('grails/grails.war')
    exploded_dir = File.join(Dir.tmpdir, "grails_exp")
    Kernel.`("unzip #{app} -d #{exploded_dir}")
    framework = VMC::Cli::Framework.detect(exploded_dir)
    Kernel.`("rm -rf #{exploded_dir}")
    framework =~ /Grails/
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