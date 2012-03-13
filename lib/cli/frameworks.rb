module VMC::Cli

  class Framework

    DEFAULT_FRAMEWORK = "http://b20nine.com/unknown"
    DEFAULT_MEM = '256M'

    FRAMEWORKS = {
      'Rails'    => ['rails3',  { :mem => '256M', :description => 'Rails Application', :console=>true}],
      'Spring'   => ['spring',  { :mem => '512M', :description => 'Java SpringSource Spring Application'}],
      'Grails'   => ['grails',  { :mem => '512M', :description => 'Java SpringSource Grails Application'}],
      'Lift'   =>   ['lift',    { :mem => '512M', :description => 'Scala Lift Application'}],
      'JavaWeb'  => ['java_web',{ :mem => '512M', :description => 'Java Web Application'}],
      'Standalone'     => ['standalone',    { :mem => '64M', :description => 'Standalone Application'}],
      'Sinatra'  => ['sinatra', { :mem => '128M', :description => 'Sinatra Application'}],
      'Node'     => ['node',    { :mem => '64M',  :description => 'Node.js Application'}],
      'PHP'      => ['php',     { :mem => '128M', :description => 'PHP Application'}],
      'Erlang/OTP Rebar' => ['otp_rebar',  { :mem => '64M',  :description => 'Erlang/OTP Rebar Application'}],
      'WSGI'     => ['wsgi',    { :mem => '64M',  :description => 'Python WSGI Application'}],
      'Django'   => ['django',  { :mem => '128M', :description => 'Python Django Application'}],
      'Rack'     => ['rack', { :mem => '128M', :description => 'Rack Application'}]
    }

    class << self

      def known_frameworks
        FRAMEWORKS.keys
      end

      def lookup(name)
        return Framework.new(*FRAMEWORKS[name])
      end

      def lookup_by_framework(name)
        FRAMEWORKS.each do |key,fw|
          return Framework.new(fw[0], fw[1]) if fw[0] == name
        end
      end

      def require_url(framework_name)
        return false if framework_name == "standalone"
        true
      end

      def require_start_command(framework_name)
        return true if framework_name == "standalone"
        false
      end

      def detect_default_runtime(path, framework_name)
        return nil if framework_name != "standalone"
        if !File.directory? path
          if path =~ /\.(jar|class)$/
            return "java"
          elsif path =~ /\.(rb)$/
            return "ruby18"
          elsif path =~ /\.(zip)$/
            return detect_runtime_from_zip path
          end
        else
          Dir.chdir(path) do
            return "ruby18" if not Dir.glob('**/*.rb').empty?
            if !Dir.glob('**/*.class').empty? || !Dir.glob('**/*.jar').empty?
              return "java"
            elsif Dir.glob('*.zip').first
              zip_file = Dir.glob('*.zip').first
              return detect_runtime_from_zip zip_file
            end
          end
        end
        return "none"
      end

      def detect_default_memory(framework_name, runtime)
        default_mem = lookup_by_framework(framework_name).memory
        if framework_name == "standalone"
          default_mem='128M' if runtime =~ /\Aruby/ || runtime == "php"
          default_mem='512M' if runtime == "java"
        end
        default_mem
      end

      def detect(path, available_frameworks)
        if !File.directory? path
          if path.end_with?('.war')
            return detect_framework_from_war path
          end
          return Framework.lookup('Standalone')
        end
        Dir.chdir(path) do
          # Rails
          if File.exist?('config/environment.rb')
            return Framework.lookup('Rails')

          # Rack
          elsif File.exist?('config.ru') && available_frameworks.include?(["rack"])
            return Framework.lookup('Rack')

          #Java Web Apps
          elsif Dir.glob('*.war').first
            return detect_framework_from_war(Dir.glob('*.war').first)

          elsif File.exist?('WEB-INF/web.xml')
            return detect_framework_from_war

          # Simple Ruby Apps
          elsif !Dir.glob('**/*.rb').empty?
            matched_file = nil
            Dir.glob('*.rb').each do |fname|
              next if matched_file
              File.open(fname, 'r') do |f|
                str = f.read # This might want to be limited
                matched_file = fname if (str && str.match(/^\s*require[\s\(]*['"]sinatra['"]/))
              end
            end
            if matched_file
              #Sinatra apps
              f = Framework.lookup('Sinatra')
              f.exec = "ruby #{matched_file}"
              return f
            end
          # Node.js
          elsif !Dir.glob('*.js').empty?
            if File.exist?('server.js') || File.exist?('app.js') || File.exist?('index.js') || File.exist?('main.js')
              return Framework.lookup('Node')
            end

          # PHP
          elsif !Dir.glob('*.php').empty?
            return Framework.lookup('PHP')

          # Erlang/OTP using Rebar
          elsif !Dir.glob('releases/*/*.rel').empty? && !Dir.glob('releases/*/*.boot').empty?
            return Framework.lookup('Erlang/OTP Rebar')

          # Python Django
          # XXX: not all django projects keep settings.py in top-level directory
          elsif File.exist?('manage.py') && File.exist?('settings.py')
            return Framework.lookup('Django')

          # Python
          elsif !Dir.glob('wsgi.py').empty?
            return Framework.lookup('WSGI')

          #Standalone
          else
            return Framework.lookup('Standalone')
          end
        end
        nil
      end

      private
      def detect_framework_from_war(war_file=nil)
        if war_file
          contents = ZipUtil.entry_lines(war_file)
        else
          #assume we are working with current dir
          contents = Dir['**/*'].join("\n")
        end

        # Spring/Lift Variations
        if contents =~ /WEB-INF\/lib\/grails-web.*\.jar/
          return Framework.lookup('Grails')
        elsif contents =~ /WEB-INF\/lib\/lift-webkit.*\.jar/
          return Framework.lookup('Lift')
        elsif contents =~ /WEB-INF\/classes\/org\/springframework/
          return Framework.lookup('Spring')
        elsif contents =~ /WEB-INF\/lib\/spring-core.*\.jar/
          return Framework.lookup('Spring')
        elsif contents =~ /WEB-INF\/lib\/org\.springframework\.core.*\.jar/
          return Framework.lookup('Spring')
        else
          return Framework.lookup('JavaWeb')
        end
      end

      def detect_runtime_from_zip(zip_file)
        contents = ZipUtil.entry_lines(zip_file)
        if contents =~ /\.(jar|class)$/
          return "java"
        end
      end
    end

    attr_reader   :name, :description, :memory, :console
    attr_accessor :exec

    alias :mem :memory

    def initialize(framework=nil, opts={})
      @name = framework || DEFAULT_FRAMEWORK
      @memory = opts[:mem] || DEFAULT_MEM
      @description = opts[:description] || 'Unknown Application Type'
      @exec = opts[:exec]
      @console = opts[:console] || false
    end

    def to_s
      description
    end
  end

end
