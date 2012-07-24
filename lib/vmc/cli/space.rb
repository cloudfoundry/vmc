require "vmc/cli"
require "vmc/cli/helpers/app"
require "vmc/cli/helpers/service"

module VMC
  class Space < CLI
    include CLI::AppHelpers
    include CLI::ServiceHelpers

    def precondition
      super
      fail "This command is v2-only." unless v2?
    end

    def self.by_name(what, obj = what)
      proc { |name, *_|
        client.send(:"#{obj}_by_name", name) ||
          fail("Unknown #{what} '#{name}'")
      }
    end

    desc "Show space information."
    group :spaces
    input(:space, :argument => :optional, :from_given => by_name("space"),
          :desc => "Space to dump") {
      client.current_space
    }
    input :full, :type => :boolean,
      :desc => "Show full information for apps, service instances, etc."
    def space(input)
      space = input[:space]

      puts "name: #{c(space.name, :name)}"
      puts "organization: #{c(space.organization.name, :name)}"

      if input[:full]
        puts ""
        puts "apps:"
        num = 0
        space.apps.each do |a|
          puts "" unless quiet? || num == 0
          display_app(a, 1)
          num += 1
        end
      else
        puts "apps: #{name_list(space.apps)}"
      end

      if input[:full]
        puts ""
        puts "services:"
        num = 0
        space.service_instances.each do |i|
          puts "" unless quiet? || num == 0
          display_service_instance(i, 1)
          num += 1
        end
      else
        puts "services: #{name_list(space.service_instances)}"
      end
    end

    private

    def name_list(xs)
      if xs.empty?
        c("none", :dim)
      else
        xs.collect { |x| c(x.name, :name) }.join(", ")
      end
    end
  end
end
