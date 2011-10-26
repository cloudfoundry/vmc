module VMC::Cli::Command

  class User < Base

    def info
      info = client_info
      username = info[:user] || 'N/A'
      return display JSON.pretty_generate([username]) if @options[:json]
      display "\n[#{username}]"
    end

    def login(email=nil)
      email    = @options[:email] unless email
      password = @options[:password]
      tries ||= 0

      prompt_entry_hash={}

      unless no_prompt

        if(!login_info[:prompts].nil?)

          #Get the prompt information for this org
          prompts = login_info[:prompts]

          prompts.each do |prompt_name, prompt_configuration|

            if(prompt_configuration[0] == :hidden.to_s)
              prompt_entry_hash[prompt_name] = ask(prompt_configuration[1], :echo => "*")
            else
              prompt_entry_hash[prompt_name] = ask(prompt_configuration[1])
              if(prompt_configuration[0] == :id.to_s)
                email = prompt_entry_hash[prompt_name]
              end
            end

          end

          login_with_custom_credentials_and_save_token(email, prompt_entry_hash)

        else
          email ||= ask("Email")
          password ||= ask("Password", :echo => "*")
          err "Need a valid email" unless email
          err "Need a password" unless password
          login_and_save_token(email, password)
        end

      end

      say "Successfully logged into [#{target_url}]".green
    rescue VMC::Client::TargetError
      display "Problem with login, invalid account or password.".red
      retry if (tries += 1) < 3 && prompt_ok && !@options[:password]
      exit 1
    rescue => e
      display "Problem with login, #{e}, try again or register for an account.".red
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

    def login_and_save_token(email, password)
      token = client.login(email, password)
      VMC::Cli::Config.store_token(token)
    end

    def login_with_custom_credentials_and_save_token(email, prompt_entry_hash)
      token = client.login(email, prompt_entry_hash)
      VMC::Cli::Config.store_token(token)
    end

  end

end
