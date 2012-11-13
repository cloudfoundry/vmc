require "set"
require "yaml"

require "vmc/constants"
require "vmc/cli"

module VMC
  module Plugin
    @@plugins = []

    def self.load_all
      # auto-load gems with 'vmc-plugin' in their name
      matching =
        if Gem::Specification.respond_to? :find_all
          Gem::Specification.find_all do |s|
            s.name =~ /vmc-plugin/
          end
        else
          Gem.source_index.find_name(/vmc-plugin/)
        end

      enabled = Set.new(matching.collect(&:name))

      # skip plugin loading if vmc being run from source
      # rather than from RubyGems executable
      if Gem.loaded_specs["vmc"]
        Gem.loaded_specs["vmc"].dependencies.each do |dep|
          if dep.name =~ /vmc-plugin/ && dep.type == :runtime
            require "#{dep.name}/plugin"
            enabled.delete dep.name
          end
        end
      else
        puts "Plugin loading unavailable if not running vmc from rubygems"
      end

      # allow explicit enabling/disabling of gems via config
      plugins = File.expand_path(VMC::PLUGINS_FILE)
      if File.exists?(plugins) && yaml = YAML.load_file(plugins)
        enabled += yaml["enabled"] if yaml["enabled"]
        enabled -= yaml["disabled"] if yaml["disabled"]
      end

      # load up each gem's 'plugin' file
      #
      # we require this file specifically so people can require the gem
      # without it plugging into VMC
      enabled.each do |gemname|
        require "#{gemname}/plugin"
      end
    end
  end
end
