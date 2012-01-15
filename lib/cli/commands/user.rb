module VMC::Cli::Command

  class User < Base

    def info
      info = client_info
      username = info[:user] || 'N/A'
      return display JSON.pretty_generate([username]) if @options[:json]
      display "\n[#{username}]"
    end

    def login(email=nil)
      tries ||= 0
      creds ||= {}
      #authn_target ||= client_info[:authenticationEndpoint]
      authn_target = nil
      
      # get prompts from UAA or fill in default prompts for backward 
      # compatibility with pre-UAA CF instances
      prompts ||= authn_target ? client.login_info(authn_target)[:prompts] :
        { :email => [:text, "Email"], :password => [:password, "Password"]}
      
      unless prompts && prompts.length > 0
        err "invalid login info received from authentication endpoint #{authn_target}"
      end
      
      if no_prompt
        if prompts.length != 2 || !prompts[:email] || !prompts[:password]
          err "cannot support no_prompt option with this authentication endpoint #{authn_target}"
        end 
        err "Need a valid email" unless @options[:email]
        creds[:email] = @options[:email]
        err "Need a password" unless @options[:password]
        creds[:password] = @options[:password]
      else
        prompts.each do |k, v|
          if v[0] == "text"
            creds[k] = (k == :email && @options[:email]) ? @options[:email] : ask(v[1], :default => creds[k])
          elsif v[0] == "password"
            creds[k] = (k == :password && @options[:password]) ? @options[:password]: ask(v[1], :echo => "*")
          else
            err "Unknown prompt type \"#{v[0]}\" received from #{authn_target}"
          end
        end
      end

      login_and_save_token(authn_target, creds)
      say "Successfully logged into [#{target_url}]".green
    rescue VMC::Client::TargetError
      display "Problem with login, invalid account or login information.".red
      retry if (tries += 1) < 3 && prompt_ok && !@options[:password]
      exit 1
    rescue => e
      display "Problem with login to '#{target_url}', #{e}, try again or register for an account.".red
      exit 1
    end

    def logout
      VMC::Cli::Config.remove_token_file
      say "Successfully logged out of [#{target_url}]".green
    end

    def change_password(password=nil)
      info = client_info
      email = info[:user]
      err "Need to be logged in to change password." unless email
      say "Changing password for '#{email}'\n"
      unless no_prompt
        password = ask "New Password", :echo => "*"
        password2 = ask "Verify Password", :echo => "*"
        err "Passwords did not match, try again" if password != password2
      end
      err "Password required" unless password
      client.change_password(password)
      say "\nSuccessfully changed password".green
    end

    private

    # NOTE: this is prototype code for adding support for a separate
    # authentication endpoint. The goal here is to get support added
    # with minimal changes to the overall VMC code. 
    # TODO: tokens should be stored in the token file as token
    # per target_url/authn_target
    def login_and_save_token(authn_target, creds)
      token = client.login_to_uaa(authn_target, creds)
      VMC::Cli::Config.store_token(token, @options[:token_file])
    end

  end

end
