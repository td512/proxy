require 'sinatra'
require 'json'
require 'yaml'
require 'rest-client'

# Key checks
def check_key(key)
  config = YAML.load_file 'keys.yml'
  halt 401 if key != config['key']
end

# Save
def save(hash)
  File.open('register.yml', 'w') { |f| YAML.dump(hash, f) }
end

# Create register if it doesn't exist
puts "Starting up..."
unless File.exists?("register.yml")
      File.new("register.yml", "w+")
end

get '/register' do
  headers\
  "Server" => 'monarch-proxy'
  content_type :json
  check_key params[:key]
  halt 500 if !params[:app] && !params[:ip] && !params[:port] && !params[:path] && !params[:dpath] && !params[:type] && !params[:appkey]
  register = YAML.load_file 'register.yml'
  register = Hash.new if register == false
  register[params[:app]] = Hash.new
  register[params[:app]]["ip"] = params[:ip]
  register[params[:app]]["port"] = params[:port]
  register[params[:app]]["path"] = params[:path]
  register[params[:app]]["dpath"] = params[:dpath]
  register[params[:app]]["type"] = params[:type]
  register[params[:app]]["appkey"] = params[:appkey]
  save register
  {:message => "registered"}.to_json
end

get '/deregister' do
  headers\
  "Server" => 'monarch-proxy'
  content_type :json
  check_key params[:key]
  halt 500 if !params[:app]
  register = YAML.load_file 'register.yml'
  register.delete(params[:app])
  save register
  {:message => "deleted"}.to_json
end

get '/deploy' do
  headers\
  "Server" => 'monarch-proxy'
  content_type :json
  check_key params[:key]
  halt 500 if !params[:user]
  responses = Array.new
  register = YAML.load_file 'register.yml'
  register.each do |r, d|
    begin
      if d["type"] == "nologin"
        loginType = "?isNoLogin=true&"
      else
        loginType = "?"
      end
      res = RestClient.get "http://#{d["ip"]}:#{d["port"]}/#{d["path"]}#{loginType}user=#{params[:user]}&key=#{d["appkey"]}"
    rescue RestClient::ExceptionWithResponse
    end
      responses.push(res.body)
  end
  puts responses
  hash = responses.map {|x| [x,true]}.to_h
  if hash.has_key? 'exists'
    'Account already exists'
  else
    'Account created'
  end
end

get '/destroy' do
  headers\
  "Server" => 'monarch-proxy'
  content_type :json
  check_key params[:key]
  halt 500 if !params[:user]
  responses = Array.new
  register = YAML.load_file 'register.yml'
  register.each do |r, d|
    begin
      res = RestClient.get "http://#{d["ip"]}:#{d["port"]}#{d["dpath"]}?user=#{params[:user]}&key=#{d["appkey"]}"
    rescue RestClient::ExceptionWithResponse
    end
end
'Account deleted'
end
