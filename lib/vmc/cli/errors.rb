module VMC::Cli

  class CliError < StandardError
    def self.error_code(code = nil)
      define_method(:error_code) { code }
    end
  end

  UnknownCommand      = Class.new(CliError) { error_code 100 }
  TargetMissing       = Class.new(CliError) { error_code 102 }
  TargetInaccessible  = Class.new(CliError) { error_code 103 }

  TargetError         = Class.new(CliError) { error_code 201 }
  AuthError           = Class.new(TargetError) { error_code 202 }

  CliExit             = Class.new(CliError) { error_code 400 }
  GracefulExit        = Class.new(CliExit) { error_code 401 }

end
