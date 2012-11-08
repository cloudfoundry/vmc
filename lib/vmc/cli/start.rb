require "vmc/cli"

module VMC
  class Start < CLI
    # Make sure we only show the target once
    @@displayed_target = false

    def displayed_target?
      @@displayed_target
    end


    # These commands don't require authentication.
    def precondition; end


    def self.find_by_name(what)
      proc { |name, choices|
        choices.find { |c| c.name == name } ||
          fail("Unknown #{what} '#{name}'")
      }
    end


    desc "Display information on the current target, user, etc."
    group :start
    input :runtimes, :type => :boolean,
      :desc => "List supported runtimes"
    input :frameworks, :type => :boolean,
      :desc => "List supported frameworks"
    input :services, :type => :boolean,
      :desc => "List supported services"
    input :all, :type => :boolean, :alias => "-a",
      :desc => "Show all information"
    def info
      all = input[:all]

      if all || input[:runtimes]
        runtimes =
          with_progress("Getting runtimes") do
            client.runtimes
          end
      end

      if all || input[:frameworks]
        frameworks =
          with_progress("Getting frameworks") do
            client.frameworks
          end
      end

      if all || input[:services]
        services =
          with_progress("Getting services") do
            client.services
          end
      end

      info = client.info

      showing_any = runtimes || services || frameworks

      unless !all && showing_any
        line if showing_any
        line info[:description]
        line
        line "target: #{b(client.target)}"

        indented do
          line "version: #{info[:version]}"
          line "support: #{info[:support]}"
        end

        if user = client.current_user
          line
          line "user: #{b(user.email || user.guid)}"
        end
      end

      if runtimes
        line unless quiet?

        if runtimes.empty? && !quiet?
          line "#{d("none")}"
        elsif input[:quiet]
          sorted_runtimes(runtimes).each do |r|
            line r.name
          end
        else
          status_colors = {
            "current" => :good,
            "next" => :name,
            "deprecated" => :bad
          }

          table(
            %w{runtime version info},
            sorted_runtimes(runtimes).collect { |r|
              if r.status
                info = r.deprecated? ? "End of Life: #{r.status[:eol_date]}" : nil
                [c(r.name, status_colors[r.status[:name]]), r.version, info]
              else
                [c(r.name, :name), r.version, nil]
              end
            })
        end
      end

      if frameworks
        line unless quiet?

        if frameworks.empty? && !quiet?
          line "#{d("none")}"
        elsif input[:quiet]
          frameworks.each do |f|
            line f.name
          end
        else
          table(
            %w{framework description},
            frameworks.sort_by(&:name).collect { |f|
              [c(f.name, :name), f.description]
            })
        end
      end

      if services
        line unless quiet?

        if services.empty? && !quiet?
          line "#{d("none")}"
        elsif input[:quiet]
          services.each do |s|
            line s.label
          end
        else
          table(
            ["service", "version", "provider", v2? && "plans", "description"],
            services.sort_by(&:label).collect { |s|
              [ c(s.label, :name),
                s.version,
                s.provider,
                v2? && s.service_plans.collect(&:name).join(", "),
                s.description
              ]
            })
        end
      end
    end

    desc "Set or display the target cloud, organization, and space"
    group :start
    input :url, :argument => :optional, :desc => "Target URL to switch to"
    input(:organization, :aliases => ["--org", "-o"],
          :from_given => find_by_name("organization"),
          :desc => "Organization") { |orgs|
      ask("Organization", :choices => orgs, :display => proc(&:name))
    }
    input(:space, :alias => "-s",
          :from_given => find_by_name("space"),
          :desc => "Space") { |spaces|
      ask("Space", :choices => spaces, :display => proc(&:name))
    }
    def target
      if !input.given?(:url) && !input.given?(:organization) && !input.given?(:space)
        display_target
        display_org_and_space unless quiet?
        return
      end

      if input.given?(:url)
        target = sane_target_url(input[:url])
        with_progress("Setting target to #{c(target, :name)}") do
          client(target).info # check that it's valid before setting
          set_target(target)
        end
      end

      return unless v2? && client.logged_in?

      if input.given?(:organization) || input.given?(:space)
        info = target_info

        select_org_and_space(input, info)

        save_target_info(info)
      end

      return if quiet?

      invalidate_client

      line
      display_target
      display_org_and_space
    end


    desc "List known targets."
    group :start, :hidden => true
    def targets
      targets_info.each do |target, _|
        line target
        # TODO: print org/space
      end
    end


    desc "Authenticate with the target"
    group :start
    input :username, :alias => "--email", :argument => :optional,
      :desc => "Account email"
    input :password, :desc => "Account password"
    input(:organization, :aliases => ["--org", "-o"],
          :from_given => find_by_name("organization"),
          :desc => "Organization") { |orgs|
      ask("Organization", :choices => orgs, :display => proc(&:name))
    }
    input(:space, :alias => "-s",
          :from_given => find_by_name("space"),
          :desc => "Space") { |spaces|
      ask("Space", :choices => spaces, :display => proc(&:name))
    }
    def login
      show_context

      credentials =
        { :username => input[:username],
          :password => input[:password]
        }

      prompts = client.login_prompts

      # ask username first
      if prompts.key? :username
        type, label = prompts.delete :username
        credentials[:username] ||= ask_prompt(type, label)
      end

      info = target_info

      authenticated = false
      failed = false
      remaining_attempts = 3
      until authenticated || remaining_attempts <= 0
        remaining_attempts -= 1
        unless force?
          ask_prompts(credentials, prompts)
        end

        with_progress("Authenticating") do |s|
          begin
            info[:token] = client.login(credentials)
            authenticated = true
          rescue CFoundry::Denied
            return if force?

            s.fail do
              failed = true
              credentials.delete(:password)
            end
          end
        end
      end

      save_target_info(info)
      invalidate_client

      if v2?
        line if input.interactive?(:organization) || input.interactive?(:space)
        select_org_and_space(input, info)
        save_target_info(info)
      end
    ensure
      exit_status 1 if not authenticated
    end


    desc "Log out from the target"
    group :start
    def logout
      with_progress("Logging out") do
        remove_target_info
      end
    end


    desc "Create a user and log in"
    group :start, :hidden => true
    input(:email, :argument => true, :desc => "Desired email") {
      ask("Email")
    }
    input(:password, :desc => "Desired password") {
      ask("Password", :echo => "*", :forget => true)
    }
    input(:verify, :desc => "Repeat password") {
      ask("Confirm Password", :echo => "*", :forget => true)
    }
    input :login, :type => :boolean, :default => true,
      :desc => "Automatically log in?"
    def register
      show_context

      email = input[:email]
      password = input[:password]

      if !force? && password != input[:verify]
        fail "Passwords do not match."
      end

      with_progress("Creating user") do
        client.register(email, password)
      end

      if input[:login]
        invoke :login, :username => email, :password => password
      end
    end


    desc "Show color configuration"
    group :start, :hidden => true
    def colors
      user_colors.each do |n, c|
        line "#{n}: #{c(c.to_s, n)}"
      end
    end

    private

    def ask_prompt(type, label)
      if type == "password"
        options = { :echo => "*", :forget => true }
      else
        options = {}
      end

      ask(label, options)
    end

    def ask_prompts(credentials, prompts)
      prompts.each do |name, meta|
        type, label = meta
        credentials[name] ||= ask_prompt(type, label)
      end
    end

    def show_context
      return if quiet? || displayed_target?

      display_target

      line

      @@displayed_target = true
    end

    def display_target
      if quiet?
        line client.target
      else
        line "target: #{c(client.target, :name)}"
      end
    end

    def display_org_and_space
      return unless v2?

      if org = client.current_organization
        line "organization: #{c(org.name, :name)}"
      end

      if space = client.current_space
        line "space: #{c(space.name, :name)}"
      end
    rescue CFoundry::APIError
    end

    def org_valid?(guid, user = client.current_user)
      return false unless guid
      client.organization(guid).users.include? user
    rescue CFoundry::APIError
      false
    end

    def space_valid?(guid, user = client.current_user)
      return false unless guid
      client.space(guid).developers.include? user
    rescue CFoundry::APIError
      false
    end

    def select_org_and_space(input, info)
      changed_org = false

      if input.given?(:organization) || !org_valid?(info[:organization])
        orgs = client.organizations
        fail "No organizations!" if orgs.empty?

        if orgs.size == 1 && !input.given?(:organization)
          org = orgs.first
        else
          org = input[:organization, orgs.sort_by(&:name)]
        end

        with_progress("Switching to organization #{c(org.name, :name)}") do
          info[:organization] = org.guid
          changed_org = true
        end
      else
        org = client.current_organization
      end

      # switching org means switching space
      if changed_org || input.given?(:space) || !space_valid?(info[:space])
        spaces = org.spaces

        if spaces.empty?
          if changed_org
            line c("There are no spaces in #{b(org.name)}.", :warning)
            line "You may want to create one with #{c("create-space", :good)}."
            return
          else
            fail "No spaces!"
          end
        end

        if spaces.size == 1 && !input.given?(:space)
          space = spaces.first
        else
          line if changed_org && input.interactive?(:organization)
          space = input[:space, spaces.sort_by(&:name)]
        end

        with_progress("Switching to space #{c(space.name, :name)}") do
          info[:space] = space.guid
        end
      end
    end

    def sorted_runtimes(runtimes)
      return runtimes if runtimes.empty?

      # Sort by name if V2 or other server that doesn't yet have category, status, series
      if v2? || !(runtimes[0].category && runtimes[0].status &&
                  runtimes[0].series)
        return runtimes.sort_by(&:name)
      end

      # Sort by category (i.e java, ruby, node, etc)
      by_category = runtimes.group_by(&:category)

      # Sort by status (current, next, deprecated)
      sorted = []
      by_category.sort.each do |category, runtimes|
        by_status = {}
        runtimes.each do |runtime|
          by_status[runtime.status[:name]] ||= []
          by_status[runtime.status[:name]] << runtime
        end

        %w(current next deprecated).each do |status|
          next unless by_status[status]
          
          # Sort by series descending (ruby19, ruby18, etc)
          by_status[status].sort_by(&:series).reverse_each do |r|
            sorted << r
          end
        end
      end

      sorted
    end
  end
end
