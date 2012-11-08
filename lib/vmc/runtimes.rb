module VMC
  module Runtimes

    def sorted_runtimes(runtimes)
      return runtimes if runtimes.empty?

      # Sort by name if using server that doesn't yet have category, status, series
      if !(runtimes[0].category && runtimes[0].status &&
                  runtimes[0].series)
        return runtimes.sort_by(&:name)
      end

      # Sort by category (i.e java, ruby, node, etc)
      by_category = runtimes.group_by(&:category)

      # Sort by status (current, next, deprecated)
      sorted = []
      by_category.sort.each do |category, runtimes|
        by_status = {}
        runtimes.each do |runtime|
          by_status[runtime.status[:name]] ||= []
          by_status[runtime.status[:name]] << runtime
        end

        %w(current next deprecated).each do |status|
          next unless by_status[status]

          # Sort by series descending (ruby19, ruby18, etc)
          by_status[status].sort_by(&:series).reverse_each do |r|
            sorted << r
          end
        end
      end

      sorted
    end

    def runtime_status_color(runtime)
      return :name if !runtime.status
      runtime_status_colors[runtime.status[:name]]
    end

    def info_for(runtime)
      runtime.deprecated? ? "End of Life: #{runtime.status[:eol_date]}" : nil
    end

    private
    def runtime_status_colors
      @status_colors ||= {
        "current" => :good,
        "next" => :neutral,
        "deprecated" => :bad
      }
    end
  end
end