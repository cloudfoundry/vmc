require 'rubygems'
require 'sinatra'

get '/' do
  host = ENV['VMC_APP_HOST']
  port = ENV['VMC_APP_PORT']
  "<h1>Hello from VCAP! via: #{host}:#{port}</h1>"
end

get '/crash/:id' do
  ps = "kill -9 #{params[:id]}"
  Kernel.`ps
end
