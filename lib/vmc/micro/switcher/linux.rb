module VMC::Micro::Switcher

  class Linux < Base
    def set_nameserver(domain, ip)
      run_command("sudo", "sed -i'.backup' '1 i nameserver #{ip}' /etc/resolv.conf")
      # lock resolv.conf so Network Manager doesn't clear out the file when offline
      run_command("sudo", "chattr +i /etc/resolv.conf")
    end

    def unset_nameserver(domain, ip)
      run_command("sudo", "chattr -i /etc/resolv.conf")
      run_command("sudo", "sed -i'.backup' '/#{ip}/d' /etc/resolv.conf")
    end
  end

end
