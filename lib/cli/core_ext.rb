module VMCExtensions

  def say(message)
    VMC::Cli::Config.output.puts(message) if VMC::Cli::Config.output
  end

  def header(message, filler = '-')
    say "\n"
    say message
    say filler.to_s * message.size
  end

  def banner(message)
    say "\n"
    say message
  end

  def display(message, nl=true)
    if nl
      say message
    else
      if VMC::Cli::Config.output
        VMC::Cli::Config.output.print(message)
        VMC::Cli::Config.output.flush
      end
    end
  end

  def clear(size=80)
    return unless VMC::Cli::Config.output
    VMC::Cli::Config.output.print("\r")
    VMC::Cli::Config.output.print(" " * size)
    VMC::Cli::Config.output.print("\r")
    #VMC::Cli::Config.output.flush
  end

  def err(message, prefix='Error: ')
    raise VMC::Cli::CliExit, "#{prefix}#{message}"
  end

  def warn(msg)
    say "#{"[WARNING]".yellow} #{msg}"
  end

  def quit(message = nil)
    raise VMC::Cli::GracefulExit, message
  end

  def blank?
    self.to_s.blank?
  end

  def uptime_string(delta)
    num_seconds = delta.to_i
    days = num_seconds / (60 * 60 * 24);
    num_seconds -= days * (60 * 60 * 24);
    hours = num_seconds / (60 * 60);
    num_seconds -= hours * (60 * 60);
    minutes = num_seconds / 60;
    num_seconds -= minutes * 60;
    "#{days}d:#{hours}h:#{minutes}m:#{num_seconds}s"
  end

  def pretty_size(size, prec=1)
    return 'NA' unless size
    return "#{size}B" if size < 1024
    return sprintf("%.#{prec}fK", size/1024.0) if size < (1024*1024)
    return sprintf("%.#{prec}fM", size/(1024.0*1024.0)) if size < (1024*1024*1024)
    return sprintf("%.#{prec}fG", size/(1024.0*1024.0*1024.0))
  end

  # a variation of `ask/choose' with...:
  #   1. a UI more consistent with the rest of VMC
  #   2. attempting type conversion based on `default'
  #   3. options list with completion/ambiguity handling
  def query(question, default_or_flags = nil, options = nil)
    if default_or_flags.is_a?(Hash)
      flags = default_or_flags
      options ||= flags[:options]
      default = flags[:default]
    else
      flags = {}
      default = default_or_flags
    end

    msg = question.dup

    if options
      if flags[:indexed]
        options.each.with_index do |o, i|
          puts "#{i + 1}: #{o}"
        end
      else
        msg << " (#{options.collect(&:inspect).join ", "})" if options
      end
    end

    case default
    when true
      msg << " [Yn]"
    when false
      msg << " [yN]"
    else
      msg << " [#{default.inspect}]" if default
    end

    print "#{msg}: "
    ans = STDIN.gets.chomp

    if ans.empty?
      if default == nil
        return query(question, default_or_flags, options)
      else
        return default
      end
    end

    if options
      match = options.select { |x| x.start_with? ans }

      if match.size == 1
        ans = match.first
      else
        if match.size > 1
          warn "Please disambiguate: #{match.join " or "}?"
        else
          if flags[:indexed] and res = options[ans.to_i - 1]
            return res
          end

          warn "Unknown answer, please try again!"
        end

        return query(question, default_or_flags, options)
      end
    end

    VMCExtensions.match_type(ans, default)
  end

  # try to make `str' be the same class as `x'
  def self.match_type(str, x)
    case x
    when Integer
      str.to_i
    when true, false
      str.upcase.start_with? "Y"
    else
      str
    end
  end

  # read a line, passing each character to a callback block
  # used primarily for password prompts where the characters are
  # displayed as stars
  def query_chars(prompt = nil)
    print "#{prompt}: " if prompt

    line = ""

    VMCExtensions.with_stty("raw -echo -icanon isig") do
      until (c = VMCExtensions.get_character) =~ /[\r\n]/
        if c == "\177" # backspace
          if line.size > 0
            line.slice!(-1, 1)
            print "\b\e[P"
          end
        else
          line << c
          yield c if block_given?
        end
      end
    end

    print "\n"

    line
  end

  begin
    require "Win32API"

    def self.with_stty(modes)
      yield
    end

    def self.get_character
      Win32API.new("crtdll", "_getch", [], "L").Call.chr
    end
  rescue LoadError
    # set tty modes for the duration of a block, restoring them afterward
    def self.with_stty(modes)
      before = `stty -g`
      system("stty #{modes}")
      yield
    ensure
      system("stty #{before}")
    end

    # this assumes we're wrapped in #with_stty
    def self.get_character
      STDIN.getc.chr
    end
  end
end

module VMCStringExtensions

  def red
    colorize("\e[0m\e[31m")
  end

  def green
    colorize("\e[0m\e[32m")
  end

  def yellow
    colorize("\e[0m\e[33m")
  end

  def bold
    colorize("\e[0m\e[1m")
  end

  def colorize(color_code)
    if VMC::Cli::Config.colorize
      "#{color_code}#{self}\e[0m"
    else
      self
    end
  end

  def blank?
    self =~ /^\s*$/
  end

  def truncate(limit = 30)
    return "" if self.blank?
    etc = "..."
    stripped = self.strip[0..limit]
    if stripped.length > limit
      stripped.gsub(/\s+?(\S+)?$/, "") + etc
    else
      stripped
    end
  end

end

class Object
  include VMCExtensions
end

class String
  include VMCStringExtensions
end
