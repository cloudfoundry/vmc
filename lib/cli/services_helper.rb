
module VMC::Cli
  module ServicesHelper
    def display_system_services(services=nil)
      services ||= client.services_info

      display "\n============== System Services ==============\n\n"

      return display "No system services available" if services.empty?

      displayed_services = []
      services.each do |service_type, value|
        value.each do |vendor, version|
          version.each do |version_str, service|
            default_plan = service[:default_plan]? service[:default_plan]: ""
            plans_str = ""
            plans_str = service[:tiers].keys.join(',') if service[:tiers]
            plans_str.sub!(/#{default_plan}/, "#{default_plan}(default)") unless default_plan.empty?
            displayed_services << [ vendor, version_str, plans_str, service[:description] ]
          end
        end
      end
      displayed_services.sort! { |a, b| a.first.to_s <=> b.first.to_s}

      services_table = table do |t|
        t.headings = 'Service', 'Version', 'Plans', 'Description'
        displayed_services.each { |s| t << s }
      end
      display services_table
    end

    def display_provisioned_services(services=nil)
      services ||= client.services
      display "\n=========== Provisioned Services ============\n\n"
      display_provisioned_services_table(services)
    end

    def display_provisioned_services_table(services)
      return unless services && !services.empty?
      services_table = table do |t|
        t.headings = 'Name', 'Service', 'Plan'
        services.each do |service|
          t << [ service[:name], service[:vendor], service[:tier] ]
        end
      end
      display services_table
    end

    def create_service_banner(service, name, display_name=false, plan=nil)
      sn = " [#{name}]" if display_name
      display "Creating Service#{sn}: ", false
      client.create_service(service, name, plan)
      display 'OK'.green
    end

    def bind_service_banner(service, appname, check_restart=true)
      display "Binding Service [#{service}]: ", false
      client.bind_service(service, appname)
      display 'OK'.green
      check_app_for_restart(appname) if check_restart
    end

    def unbind_service_banner(service, appname, check_restart=true)
      display "Unbinding Service [#{service}]: ", false
      client.unbind_service(service, appname)
      display 'OK'.green
      check_app_for_restart(appname) if check_restart
    end

    def delete_service_banner(service)
      display "Deleting service [#{service}]: ", false
      client.delete_service(service)
      display 'OK'.green
    end

    def random_service_name(service)
      r = "%04x" % [rand(0x0100000)]
      "#{service.to_s}-#{r}"
    end

    def check_app_for_restart(appname)
      app = client.app_info(appname)
      cmd = VMC::Cli::Command::Apps.new(@options)
      cmd.restart(appname) if app[:state] == 'STARTED'
    end

    def service_plans(service, services_info=nil)
      services ||= client.services_info
      services.values.collect { |type|
        type.select {|vendor, version| vendor.to_s == service}.values.collect { |ver|
          ver.values.collect { |srv|
            srv.select { |key, value| key == :tiers}.values.collect{ |plan|
              plan.keys.collect(&:to_s)
            }
          }
        }
      }.flatten
    end

  end
end
