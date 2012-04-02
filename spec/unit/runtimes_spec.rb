  require 'spec_helper'

describe 'VMC::Cli::Runtime' do

  before(:all) do
    VMC::Cli::Runtime.load_all_runtimes build_frameworks_with_runtimes_info
  end

  it "should lookup runtime for Java Web Application framework" do
    runtime = VMC::Cli::Runtime.default_runtime_for "java_web"
    runtime.name.should == "java"
    runtime.version.should == "1.6"
    runtime.description.should == "Java 6"
    runtime.default.should be_true
  end

  it "should list known runtimes" do
    runtimes = VMC::Cli::Runtime.known_runtimes
    runtimes.map do |rt_name|
       VMC::Cli::Runtime.lookup(rt_name).name
    end.should include "node", "ruby18", "ruby19", "java"
  end

  describe "sinatra framework has multi runtimes" do

    it 'should list multi runtimes' do
      runtimes = VMC::Cli::Runtime.runtimes_for "sinatra"
      runtimes.values.map {|r| r.name }.should include "ruby18", "ruby19"
    end

    it 'should list ruby18 as a default runtime' do
      default_runtime = VMC::Cli::Runtime.default_runtime_for "sinatra"
      default_runtime.name.should == "ruby18"
    end

    it 'has multi runtimes' do
      has_multi_runtimes = VMC::Cli::Runtime.has_multi_runtime? "sinatra"
      has_multi_runtimes.should be_true
    end

  end

  describe "node framework has a runtime" do

    it 'should list a runtime' do
      runtimes = VMC::Cli::Runtime.runtimes_for "node"
      runtimes.values.map {|r| r.name }.should include "node"
    end

    it 'should list node as a default runtime' do
      default_runtime = VMC::Cli::Runtime.default_runtime_for "node"
      default_runtime.name.should == "node"
    end

    it 'has a runtime' do
      has_multi_runtimes = VMC::Cli::Runtime.has_multi_runtime? "node"
      has_multi_runtimes.should be_false
    end

  end

  describe "java_web framework has a runtime" do

    it 'should list a runtime' do
      runtimes = VMC::Cli::Runtime.runtimes_for "java_web"
      runtimes.values.map {|r| r.name }.should include "java"
    end

    it 'should list node as a default runtime' do
      default_runtime = VMC::Cli::Runtime.default_runtime_for "java_web"
      default_runtime.name.should == "java"
    end

    it 'has a runtime' do
      has_multi_runtimes = VMC::Cli::Runtime.has_multi_runtime? "node"
      has_multi_runtimes.should be_false
    end

  end

  def build_frameworks_with_runtimes_info
    yml = YAML.load_file spec_asset('frameworks_with_runtimes.yml')
    frameworks_with_runtimes = {}
    yml.each_pair do |framework, runtimes_info|
      # "default", "runtimes" -> :default, :runtimes
      new_runtimes_info = {}
      runtimes_info.each_pair do |rts_key, rts_value|
        rts_value.each_pair do |rt_key, rt_value|
          # "version", "default", "description" -> :version, :default, :runtimes
          new_rt_value = {}
          rt_value.each_pair do |rt_attr_key, rt_attr|
            new_rt_value[rt_attr_key.to_sym] = rt_attr
          end
          rts_value[rt_key] = new_rt_value
        end if rts_value.is_a?(Hash)
        new_runtimes_info[rts_key.to_sym] = rts_value
      end
      frameworks_with_runtimes[framework] = new_runtimes_info
    end
    frameworks_with_runtimes
  end

end
