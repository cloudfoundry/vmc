module VMC
  def self.windows?
    !!(RUBY_PLATFORM =~ /mingw|mswin32|cygwin/)
  end
end

require 'vmc/client'
