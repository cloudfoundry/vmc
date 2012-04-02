module VMC::Cli

  class Runtime

    class << self

      def load_all_runtimes(frameworks_with_runtimes)
        @runtimes = {}
        @default_runtimes = {}
        @framework_runtimes = {}
        frameworks_with_runtimes.each_pair do |framework, runtimes_info|
          default_rt_name = runtimes_info[:default] || runtimes_info[:runtimes].keys.first
          default_rt_info = runtimes_info[:runtimes][default_rt_name]
          @default_runtimes[framework] = VMC::Cli::Runtime.new(default_rt_name, default_rt_info)
          runtimes = {}
          runtimes_info[:runtimes].each_pair do |rt_name, rt_info|
            rt = VMC::Cli::Runtime.new(rt_name, rt_info)
            runtimes[rt.to_s] = rt
          end
          @framework_runtimes[framework] = runtimes
          @runtimes.merge! runtimes
        end
      end

      def known_runtimes
        return nil unless @runtimes
        @runtimes.keys
      end

      def lookup(runtime)
        return nil unless @runtimes
        @runtimes[runtime]
      end

      def has_multi_runtime?(framework)
        runtimes = runtimes_for framework
        return false unless runtimes
        1 < runtimes.size
      end

      def default_runtime_for(framework)
        return nil unless @default_runtimes
        @default_runtimes[framework]
      end

      def runtimes_for(framework)
        return nil unless @framework_runtimes
        @framework_runtimes[framework]
      end

    end

    attr_reader :name, :version, :description, :default

    def initialize(runtime=nil, opts={})
      @name = runtime || 'unknown'
      @version = opts[:version] || '0.999'
      @description = opts[:description] || 'Unknown Runtime Type'
      @default = opts[:default] || false
    end

    def to_s
      description
    end

  end

end
