WINDOWS = !!(RUBY_PLATFORM =~ /mingw|mswin32|cygwin/)

module VMC
  autoload :Client,           "vmc/client"
  autoload :Micro,            "vmc/micro"

  module Micro
    module Switcher
      autoload :Base,         "vmc/micro/switcher/base"
      autoload :Darwin,       "vmc/micro/switcher/darwin"
      autoload :Dummy,        "vmc/micro/switcher/dummy"
      autoload :Linux,        "vmc/micro/switcher/linux"
      autoload :Windows,      "vmc/micro/switcher/windows"
    end
    autoload :VMrun,          "vmc/micro/vmrun"
  end

  module Cli
    autoload :Config,         "vmc/cli/config"
    autoload :Framework,      "vmc/cli/frameworks"
    autoload :Runner,         "vmc/cli/runner"
    autoload :ZipUtil,        "vmc/cli/zip_util"
    autoload :ServicesHelper, "vmc/cli/services_helper"
    autoload :TunnelHelper,   "vmc/cli/tunnel_helper"
    autoload :ManifestHelper, "vmc/cli/manifest_helper"
    autoload :ConsoleHelper,  "vmc/cli/console_helper"

    module Command
      autoload :Base,         "vmc/cli/commands/base"
      autoload :Admin,        "vmc/cli/commands/admin"
      autoload :Apps,         "vmc/cli/commands/apps"
      autoload :Micro,        "vmc/cli/commands/micro"
      autoload :Misc,         "vmc/cli/commands/misc"
      autoload :Services,     "vmc/cli/commands/services"
      autoload :User,         "vmc/cli/commands/user"
      autoload :Manifest,     "vmc/cli/commands/manifest"
    end

  end
end

require "vmc/cli/version"
require "vmc/cli/core_ext"
require "vmc/cli/errors"
