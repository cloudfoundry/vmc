module VMC
  autoload :Client, "vmc/client"
  autoload :Micro,  "vmc/micro"

  def self.windows?
    !!(RUBY_PLATFORM =~ /mingw|mswin32|cygwin/)
  end
end

require 'vmc/client'
