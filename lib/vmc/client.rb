# VMC client
#
# Example:
#
#   require 'vmc'
#   client = VMC::Client.new('api.vcap.me')
#   client.login(:user, :pass)
#   client.create('myapplication', manifest)
#   client.create_service('redis', 'my_redis_service', opts);
#

require 'rubygems'
require 'json/pure'
require 'open-uri'

require File.expand_path('../const', __FILE__)

class VMC::Client

  def self.version
    VMC::VERSION
  end

  attr_reader   :target, :host, :user, :proxy, :auth_token, :authen_target
  attr_accessor :trace

  # Error codes
  VMC_HTTP_ERROR_CODES = [ 400, 500 ]

  # Errors
  class BadTarget <  RuntimeError; end
  class AuthError <  RuntimeError; end
  class TargetError < RuntimeError; end
  class NotFound < RuntimeError; end
  class BadResponse < RuntimeError; end
  class HTTPException <  RuntimeError; end

  # Initialize new client to the target_uri with optional auth_token
  def initialize(target_url=VMC::DEFAULT_TARGET, auth_token=nil)
    target_url = "http://#{target_url}" unless /^https?/ =~ target_url
    target_url = target_url.gsub(/\/+$/, '')
    @target = target_url
    @auth_token = auth_token
  end

  ######################################################
  # Target info
  ######################################################

  # Retrieves information on the target cloud, and optionally the logged in user
  def info
    # TODO: Should merge for new version IMO, general, services, user_account
    json_get(VMC::INFO_PATH)
  end

  def raw_info
    http_get(VMC::INFO_PATH)
  end

  # Global listing of services that are available on the target system
  def services_info
    check_login_status
    json_get(path(VMC::GLOBAL_SERVICES_PATH))
  end

  def runtimes_info
    json_get(path(VMC::GLOBAL_RUNTIMES_PATH))
  end

  ######################################################
  # Apps
  ######################################################

  def apps
    check_login_status
    json_get(VMC::APPS_PATH)
  end

  def create_app(name, manifest={})
    check_login_status
    app = manifest.dup
    app[:name] = name
    app[:instances] ||= 1
    json_post(VMC::APPS_PATH, app)
  end

  def update_app(name, manifest)
    check_login_status
    json_put(path(VMC::APPS_PATH, name), manifest)
  end

  def upload_app(name, zipfile, resource_manifest=nil)
    #FIXME, manifest should be allowed to be null, here for compatability with old cc's
    resource_manifest ||= []
    check_login_status
    upload_data = {:_method => 'put'}
    if zipfile
      if zipfile.is_a? File
        file = zipfile
      else
        file = File.new(zipfile, 'rb')
      end
      upload_data[:application] = file
    end
    upload_data[:resources] = resource_manifest.to_json if resource_manifest
    http_post(path(VMC::APPS_PATH, name, "application"), upload_data)
  rescue RestClient::ServerBrokeConnection
    retry
  end

  def delete_app(name)
    check_login_status
    http_delete(path(VMC::APPS_PATH, name))
  end

  def app_info(name)
    check_login_status
    json_get(path(VMC::APPS_PATH, name))
  end

  def app_update_info(name)
    check_login_status
    json_get(path(VMC::APPS_PATH, name, "update"))
  end

  def app_stats(name)
    check_login_status
    stats_raw = json_get(path(VMC::APPS_PATH, name, "stats"))
    stats = []
    stats_raw.each_pair do |k, entry|
      # Skip entries with no stats
      next unless entry[:stats]
      entry[:instance] = k.to_s.to_i
      entry[:state] = entry[:state].to_sym if entry[:state]
      stats << entry
    end
    stats.sort { |a,b| a[:instance] - b[:instance] }
  end

  def app_instances(name)
    check_login_status
    json_get(path(VMC::APPS_PATH, name, "instances"))
  end

  def app_crashes(name)
    check_login_status
    json_get(path(VMC::APPS_PATH, name, "crashes"))
  end

  # List the directory or download the actual file indicated by
  # the path.
  def app_files(name, path, instance='0')
    check_login_status
    path = path.gsub('//', '/')
    url = path(VMC::APPS_PATH, name, "instances", instance, "files", path)
    _, body, headers = http_get(url)
    body
  end

  ######################################################
  # Services
  ######################################################

  # listing of services that are available in the system
  def services
    check_login_status
    json_get(VMC::SERVICES_PATH)
  end

  def create_service(service, name)
    check_login_status
    services = services_info
    services ||= []
    service_hash = nil

    service = service.to_s

    # FIXME!
    services.each do |service_type, value|
      value.each do |vendor, version|
        version.each do |version_str, service_descr|
          if service == service_descr[:vendor]
            service_hash = {
              :type => service_descr[:type], :tier => 'free',
              :vendor => service, :version => version_str
            }
            break
          end
        end
      end
    end

    raise TargetError, "Service [#{service}] is not a valid service choice" unless service_hash
    service_hash[:name] = name
    json_post(path(VMC::SERVICES_PATH), service_hash)
  end

  def delete_service(name)
    check_login_status
    svcs = services || []
    names = svcs.collect { |s| s[:name] }
    raise TargetError, "Service [#{name}] not a valid service" unless names.include? name
    http_delete(path(VMC::SERVICES_PATH, name))
  end

  def bind_service(service, appname)
    check_login_status
    app = app_info(appname)
    services = app[:services] || []
    app[:services] = services << service
    update_app(appname, app)
  end

  def unbind_service(service, appname)
    check_login_status
    app = app_info(appname)
    services = app[:services] || []
    services.delete(service)
    app[:services] = services
    update_app(appname, app)
  end

  ######################################################
  # Resources
  ######################################################

  # Send in a resources manifest array to the system to have
  # it check what is needed to actually send. Returns array
  # indicating what is needed. This returned manifest should be
  # sent in with the upload if resources were removed.
  # E.g. [{:sha1 => xxx, :size => xxx, :fn => filename}]
  def check_resources(resources)
    check_login_status
    status, body, headers = json_post(VMC::RESOURCES_PATH, resources)
    json_parse(body)
  end

  ######################################################
  # Validation Helpers
  ######################################################

  # Checks that the target is valid
  def target_valid?
    return false unless descr = info
    return false unless descr[:name]
    return false unless descr[:build]
    return false unless descr[:version]
    return false unless descr[:support]
    true
  rescue
    false
  end

  # Checks that the auth_token is valid
  def logged_in?
    descr = info
    if descr
      return false unless descr[:user]
      return false unless descr[:usage]
      @user = descr[:user]
      true
    end
  end

  ######################################################
  # User login/password
  ######################################################

  # Auth token can be retained and used in creating new clients, avoiding login.
  # this will only get pre-UAA tokens from the cloud controller
  #
  # This interface is left here to ease transition for pre-uaa code written to
  # login using email/password to the cloud controller. It assumes the
  # email/password credentials have been passed in from something like
  # test or legacy code and cannot collect other credentials from the user.
  def login(user, password)

    return login_with_credentials(:username => user, :password => password) if authen_target

    status, body, headers = json_post(path(VMC::USERS_PATH, user, "tokens"), {:password => password})
    response_info = json_parse(body)
    if response_info
      @user = user
      @auth_token = response_info[:token]
    end
  end

  # NOTE: this is prototype code for adding support for a separate
  # authentication endpoint. The goal here is to get support added
  # with minimal changes to the overall VMC code. Some requests need to
  # go to authen_target rather than :target, so, rather than change all
  # lower level calls to take the target, we just set @tmp_authn_target before
  # each request to the lower level functions.
  # In the low level request method if @tmp_authn_target is non-nil, the request
  # is sent to that endpoint instead of :target and then the code ensures that
  # @tmp_authn_target is reset to nil after each request.
  # TODO: Clean up situation for the above note.
  # TODO: There is currently no way to authenticate the call to the UAA to
  #    support add user, etc. The auth_token only goes to the :target endpoint
  #    and there is currently no support for a separate auth_token for the
  #    authen_target endpoint.

  def authen_target
    @authen_target ||= ENV["VMC_AUTHEN_TARGET"] || info[:authorization_endpoint]
  end

  # get login info, including prompts for user credentials
  def login_prompts
    if !(@tmp_authn_target = authen_target)
      prompts = { :username => ["text", "Email"], :password => ["password", "Password"] }
    elsif !(prompts = json_get(path(VMC::LOGIN_INFO_PATH))[:prompts])
      raise BadTarget, "no login prompts received from authentication target #{authen_target}"
    end
    prompts
  end

  # per-UAA login and return an auth_token
  # Auth token can be retained and used in creating new clients, avoiding login.
  def login_with_credentials(creds)

    return login(creds[:username], creds[:password]) unless authen_target

    @tmp_authn_target = authen_target

    # we have tmp_authn_target, do the OAuth2 dance to the UAA
    uri = "#{path(VMC::LOGIN_TOKEN_PATH)}?client_id=vmc&response_type=token&scope=read" +
          "&redirect_uri=#{URI.encode('http://uaa.cloudfoundry.com/redirect/vmc')}"
    body = URI.encode_www_form(:credentials => creds.to_json)
    headers = {'Content-Type' => 'application/x-www-form-urlencoded',
          'Accept' => 'application/json'}
    status, body, headers = request(:post, uri, nil, body, headers)

    unless status == 302
      raise BadTarget, "received unexpected HTTP response from authentication target #{authen_target}: #{status}"
    end

    location = headers[:location].split('#')
    unless location.length == 2 && location[0] == 'http://uaa.cloudfoundry.com/redirect/vmc'
      raise BadTarget, "received invalid response from authentication target #{authen_target}"
    end

    values = {}
    location[1].split('&').each do |kvp|
      mtch = /(.+?)=(.+)/.match(kvp)
      values[mtch[1].to_sym] = mtch[2]
    end

    unless values[:token_type] && values[:access_token]
      raise BadTarget, "received insufficient token information in response from authentication target #{authen_target}"
    end

    # If the ENV["VMC_AUTHEN_TARGET"] is set, we expect the CC does not know
    # about UAA-style tokens -- therefore this may be a legacy mode token and
    # we leave off the token type.
    @auth_token = ENV["VMC_AUTHEN_TARGET"] ? "" : URI.decode(values[:token_type]) + " "
    @auth_token += "#{URI.decode(values[:access_token])}"
  end

  # sets the password for the current logged user
  def change_password(new_password)
    check_login_status
    user_info = json_get(path(VMC::USERS_PATH, @user))
    if user_info
      user_info[:password] = new_password
      json_put(path(VMC::USERS_PATH, @user), user_info)
    end
  end

  ######################################################
  # System administration
  ######################################################

  def proxy=(proxy)
    @proxy = proxy
  end

  def proxy_for(proxy)
    @proxy = proxy
  end

  def users
    check_login_status
    json_get(VMC::USERS_PATH)
  end

  def add_user(user_email, password)
    json_post(VMC::USERS_PATH, { :email => user_email, :password => password })
  end

  def delete_user(user_email)
    check_login_status
    http_delete(path(VMC::USERS_PATH, user_email))
  end

  ######################################################

  def self.path(*path)
    path.flatten.collect { |x|
      URI.encode x.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")
    }.join("/")
  end

  private

  def path(*args, &blk)
    self.class.path(*args, &blk)
  end

  def json_get(url)
    status, body, headers = http_get(url, 'application/json')
    json_parse(body)
  rescue JSON::ParserError
    raise BadResponse, "Can't parse response into JSON", body
  end

  def json_post(url, payload)
    http_post(url, payload.to_json, 'application/json')
  end

  def json_put(url, payload)
    http_put(url, payload.to_json, 'application/json')
  end

  def json_parse(str)
    if str
      JSON.parse(str, :symbolize_names => true)
    end
  end

  require 'rest_client'

  # HTTP helpers

  def http_get(path, content_type=nil)
    request(:get, path, content_type)
  end

  def http_post(path, body, content_type=nil)
    request(:post, path, content_type, body)
  end

  def http_put(path, body, content_type=nil)
    request(:put, path, content_type, body)
  end

  def http_delete(path)
    request(:delete, path)
  end

  def request(method, path, content_type = nil, payload = nil, headers = {})
    headers = headers.dup
    headers['AUTHORIZATION'] = @auth_token if @auth_token && !@tmp_authn_target
    headers['PROXY-USER'] = @proxy if @proxy

    if content_type
      headers['Content-Type'] = content_type
      headers['Accept'] = content_type
    end

    req = {
      :method => method,
      :url => @tmp_authn_target ? "#{@tmp_authn_target}/#{path}" : "#{@target}/#{path}",
      :payload => payload, :headers => headers, :multipart => true
    }
    status, body, response_headers = perform_http_request(req)

    if request_failed?(status)
      # FIXME, old cc returned 400 on not found for file access
      err = (status == 404 || status == 400) ? NotFound : TargetError
      raise err, parse_error_message(status, body)
    else
      return status, body, response_headers
    end
  rescue URI::Error, SocketError, Errno::ECONNREFUSED => e
    raise BadTarget, "Cannot access target (%s)" % [ e.message ]
  ensure
    @tmp_authn_target = nil
  end

  def request_failed?(status)
    VMC_HTTP_ERROR_CODES.detect{|error_code| status >= error_code}
  end

  def perform_http_request(req)
    proxy_uri = URI.parse(req[:url]).find_proxy()
    RestClient.proxy = proxy_uri.to_s if proxy_uri

    # Setup tracing if needed
    unless trace.nil?
      req[:headers]['X-VCAP-Trace'] = (trace == true ? '22' : trace)
    end

    result = nil
    RestClient::Request.execute(req) do |response, request|
      result = [ response.code, response.body, response.headers ]
      unless trace.nil?
        puts '>>>'
        puts "PROXY: #{RestClient.proxy}" if RestClient.proxy
        puts "REQUEST: #{req[:method]} #{req[:url]}"
        puts "REQUEST_HEADERS:"
        req[:headers].each do |key, value|
            puts "    #{key} : #{value}"
        end
        puts "REQUEST_BODY: #{req[:payload]}" if req[:payload]
        puts "RESPONSE_HEADERS:"
        response.headers.each do |key, value|
            puts "    #{key} : #{value}"
        end
        puts "RESPONSE: [#{response.code}]"
        begin
            puts JSON.pretty_generate(JSON.parse(response.body))
        rescue
            puts "#{response.body}"
        end
        puts '<<<'
      end
    end
    result
  rescue Net::HTTPBadResponse => e
    raise BadTarget "Received bad HTTP response from target: #{e}"
  rescue SystemCallError, RestClient::Exception => e
    raise HTTPException, "HTTP exception: #{e.class}:#{e}"
  end

  def truncate(str, limit = 30)
    etc = '...'
    stripped = str.strip[0..limit]
    if stripped.length > limit
      stripped + etc
    else
      stripped
    end
  end

  def parse_error_message(status, body)
    parsed_body = json_parse(body.to_s)
    if parsed_body && parsed_body[:code] && parsed_body[:description]
      desc = parsed_body[:description].gsub("\"","'")
      "Error #{parsed_body[:code]}: #{desc}"
    else
      "Error (HTTP #{status}): #{body}"
    end
  rescue JSON::ParserError
    if body.nil? || body.empty?
      "Error (#{status}): No Response Received"
    else
      body_out = trace ? body : truncate(body)
      "Error (JSON #{status}): #{body_out}"
    end
  end

  def check_login_status
    raise AuthError unless @user || logged_in?
  end

end
