module VMC::CLI::ServiceHelpers
  private

  def display_service_instance(i, indent = 0)
    if quiet?
      puts i.name
    else
      indentation = "  " * indent

      plan = i.service_plan
      service = plan.service

      puts "#{indentation}#{c(i.name, :name)}: #{service.label} #{service.version}"
      puts "#{indentation}  description: #{service.description}"
      puts "#{indentation}  plan: #{c(plan.name, :name)}"
      puts "#{indentation}    description: #{plan.description}"
    end
  end
end
