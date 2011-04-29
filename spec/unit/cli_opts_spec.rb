require 'spec_helper'

describe 'VMC::Cli::Runner' do

  it 'should parse email and password correctly' do
    args = "--email derek@gmail.com --password foo"
    cli = VMC::Cli::Runner.new(args.split).parse_options!
    cli.options[:email].should == 'derek@gmail.com'
    cli.options[:password].should == 'foo'
  end

  it 'should parse multiple variations of password' do
    args = "--password foo"
    cli = VMC::Cli::Runner.new(args.split).parse_options!
    cli.options[:password].should == 'foo'

    args = "--pass foo"
    cli = VMC::Cli::Runner.new(args.split).parse_options!
    cli.options[:password].should == 'foo'

    args = "--passwd foo"
    cli = VMC::Cli::Runner.new(args.split).parse_options!
    cli.options[:password].should == 'foo'
  end

  it 'should parse name and bind args correctly' do
    args = "--name foo --bind bar"
    cli = VMC::Cli::Runner.new(args.split).parse_options!
    cli.options[:name].should == 'foo'
    cli.options[:bind].should == 'bar'
  end

  it 'should parse instance and instances correctly into numbers' do
    args = "--instances 1 --instance 2"
    cli = VMC::Cli::Runner.new(args.split).parse_options!
    cli.options[:instances].should == 1
    cli.options[:instance].should == 2
  end

  it 'should complain if instance arg is not a number' do
    args = "--instance foo"
    expect { VMC::Cli::Runner.new(args.split).parse_options! }.to raise_error
  end

  it 'should parse url, mem, path correctly' do
    args = "--mem 64 --url http://foo.vcap.me --path ~derek"
    cli = VMC::Cli::Runner.new(args.split).parse_options!
    cli.options[:mem].should == '64'
    cli.options[:url].should == 'http://foo.vcap.me'
    cli.options[:path].should == '~derek'
  end

  it 'should parse multiple forms of nostart correctly' do
    cli = VMC::Cli::Runner.new().parse_options!
    cli.options[:nostart].should_not be
    args = "--nostart"
    cli = VMC::Cli::Runner.new(args.split).parse_options!
    cli.options[:nostart].should be_true
    args = "--no-start"
    cli = VMC::Cli::Runner.new(args.split).parse_options!
    cli.options[:nostart].should be_true
  end

  it 'should parse force and all correctly' do
    args = "--force --all"
    cli = VMC::Cli::Runner.new(args.split).parse_options!
    cli.options[:force].should be_true
    cli.options[:all].should be_true
  end

  it "should parse tunnel options correctly" do
    args = "--tunnel-host 1.2.3.4 --tunnel-user user --tunnel-password pass --tunnel-port 1234"
    cli = VMC::Cli::Runner.new(args.split).parse_options!
    cli.options[:tunnel_host].should == "1.2.3.4"
    cli.options[:tunnel_user].should == "user"
    cli.options[:tunnel_password].should == "pass"
    cli.options[:tunnel_port].should == "1234"
  end

  it "should get default tunnel options correctly" do
    args = ""
    cli = VMC::Cli::Runner.new(args.split).parse_options!
    cli.options[:tunnel_user].should == "vcap"
    cli.options[:tunnel_port].should == 80
  end
end
