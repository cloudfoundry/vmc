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

  # general-purpose interaction
  #
  # `question' is the prompt (without ": " at the end)
  # `options' is a hash containing:
  #   :input - the input source (defaults to STDIN)
  #   :default - the default value, also used to attempt type conversion
  #              of the answer (e.g. numeric/boolean)
  #   :choices - a list of strings to choose from
  #   :indexed - whether to allow choosing from `:choices' by their index,
  #              best for when there are many choices
  #   :each_char - a block called when each character is entered.
  #                if provided, each character received is passed to the
  #                block rather than being printed to the screen.
  #                used for e.g. password prompts.
  def ask(question, options = {})
    default = options[:default]
    choices = options[:choices]
    indexed = options[:indexed]
    each_char = options[:each_char]
    input = options[:input] || STDIN

    if choices
      VMCExtensions.ask_choices(input, question, default, choices, indexed)
    else
      VMCExtensions.ask_default(input, question, default, &each_char)
    end
  end

  # ask a simple question, maybe with a default answer
  #
  # reads character-by-character, handling backspaces, and sending each
  # character to a block if provided
  def self.ask_default(input, question, default = nil, &callback)
    # print out each character by default, as in normal interaction
    callback ||= proc { |c| display c, false }

    while true
      VMCExtensions.prompt(question, default)

      ans = ""

      VMCExtensions.with_char_io(input) do
        until (c = VMCExtensions.get_character(input)) =~ /[\r\n]/
          if c == "\177" or c == "\b" # backspace
            if ans.size > 0
              ans.slice!(-1, 1)

              if c == "\b" # windows
                display "\b \b", false
              else # unix
                display "\b\e[P", false
              end
            end
          elsif c == "\x03"
            raise Interrupt.new
          else
            ans << c
            callback.call(c)
          end
        end
      end

      display "\n", false

      if ans.empty?
        return default unless default.nil?
      else
        return VMCExtensions.match_type(ans, default)
      end
    end
  end

  def self.ask_choices(input, question, default, choices, indexed = false)
    msg = question.dup

    if indexed
      choices.each.with_index do |o, i|
        say "#{i + 1}: #{o}"
      end
    else
      msg << " (#{choices.collect(&:inspect).join ", "})"
    end

    while true
      ans = VMCExtensions.ask_default(input, msg, default)

      matches = choices.select { |x| x.start_with? ans }

      if matches.size == 1
        return matches.first
      elsif indexed and ans =~ /^\d+$/ and res = choices.to_a[ans.to_i - 1]
        return res
      elsif matches.size > 1
        warn "Please disambiguate: #{matches.join " or "}?"
      else
        warn "Unknown answer, please try again!"
      end
    end
  end

  # display a question and show the default value
  def self.prompt(question, default = nil)
    msg = question.dup

    case default
    when true
      msg << " [Yn]"
    when false
      msg << " [yN]"
    else
      msg << " [#{default.inspect}]" if default
    end

    display "#{msg}: ", false
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

  # definitions for reading character-by-character
  begin
    require "Win32API"

    def self.with_char_io(input)
      yield
    end

    def self.get_character(input)
      if input == STDIN
        begin
          Win32API.new("msvcrt", "_getch", [], "L").call.chr
        rescue
          Win32API.new("crtdll", "_getch", [], "L").call.chr
        end
      else
        input.getc.chr
      end
    end
  rescue LoadError
    begin
      require "termios"

      def self.with_char_io(input)
        return yield unless input.tty?

        before = Termios.getattr(input)

        new = before.dup
        new.c_lflag &= ~(Termios::ECHO | Termios::ICANON)
        new.c_cc[Termios::VMIN] = 1

        begin
          Termios.setattr(input, Termios::TCSANOW, new)
          yield
        ensure
          Termios.setattr(input, Termios::TCSANOW, before)
        end
      end

      def self.get_character(input)
        input.getc.chr
      end
    rescue LoadError
      # set tty modes for the duration of a block, restoring them afterward
      def self.with_char_io(input)
        return yield unless input.tty?

        begin
          before = `stty -g`
          system("stty raw -echo -icanon isig")
          yield
        ensure
          system("stty #{before}")
        end
      end

      # this assumes we're wrapped in #with_stty
      def self.get_character(input)
        input.getc.chr
      end
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
