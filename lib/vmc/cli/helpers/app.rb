module VMC::CLI::AppHelpers
  IS_UTF8 = !!(ENV["LC_ALL"] || ENV["LC_CTYPE"] || ENV["LANG"])["UTF-8"]

  private

  def display_app(a, indent = 0)
    i = "  " * indent

    if quiet?
      puts a.name
      return
    end

    status = app_status(a)

    puts "#{i}#{c(a.name, :name)}: #{status}"

    puts "#{i}  platform: #{b(a.framework.name)} on #{b(a.runtime.name)}"

    print "#{i}  usage: #{b(human_size(a.memory * 1024 * 1024, 0))}"
    print " #{c(IS_UTF8 ? "\xc3\x97" : "x", :dim)} #{b(a.total_instances)}"
    print " instance#{a.total_instances == 1 ? "" : "s"}"
    puts ""

    unless a.urls.empty?
      puts "#{i}  urls: #{a.urls.collect { |u| b(u) }.join(", ")}"
    end

    unless a.services.empty?
      print "#{i}  services: "
      puts a.services.collect { |s| b(s.name) }.join(", ")
    end
  end

  # choose the right color for app/instance state
  def state_color(s)
    case s
    when "STARTING"
      :neutral
    when "STARTED", "RUNNING"
      :good
    when "DOWN"
      :bad
    when "FLAPPING"
      :error
    when "N/A"
      :unknown
    else
      :warning
    end
  end

  def app_status(a)
    health = a.health

    if a.debug_mode == "suspend" && health == "0%"
      c("suspended", :neutral)
    else
      c(health.downcase, state_color(health))
    end
  end

  def usage(used, limit)
    "#{b(human_size(used))} of #{b(human_size(limit, 0))}"
  end

  def percentage(num, low = 50, mid = 70)
    color =
      if num <= low
        :good
      elsif num <= mid
        :warning
      else
        :bad
      end

    c(format("%.1f\%", num), color)
  end

  def megabytes(str)
    if str =~ /T$/i
      str.to_i * 1024 * 1024
    elsif str =~ /G$/i
      str.to_i * 1024
    elsif str =~ /M$/i
      str.to_i
    elsif str =~ /K$/i
      str.to_i / 1024
    else # assume megabytes
      str.to_i
    end
  end

  def human_size(num, precision = 1)
    sizes = ["G", "M", "K"]
    sizes.each.with_index do |suf, i|
      pow = sizes.size - i
      unit = 1024 ** pow
      if num >= unit
        return format("%.#{precision}f%s", num / unit, suf)
      end
    end

    format("%.#{precision}fB", num)
  end

  def display_instance(i)
    print "instance #{c("\##{i.index}", :instance)}: "
    puts "#{b(c(i.state.downcase, state_color(i.state)))} "

    puts "  started: #{c(i.since.strftime("%F %r"), :cyan)}"

    if d = i.debugger
      puts "  debugger: port #{b(d[:port])} at #{b(d[:ip])}"
    end

    if c = i.console
      puts "  console: port #{b(c[:port])} at #{b(c[:ip])}"
    end
  end
end
