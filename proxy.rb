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
puts 'Starting up...'
File.new('register.yml', 'w+') unless File.exist?('register.yml')
set :bind, '0.0.0.0'

get '/register' do
  headers\
    'Server' => 'monarch-proxy'
  content_type :json
  check_key params[:key]
  halt 500 if !params[:app] || !params[:ip] || !params[:port] || \
              !params[:path] || !params[:dpath] || !params[:type] || \
              !params[:appkey]
  register = YAML.load_file 'register.yml'
  register = {} if register == false
  register[params[:app]] = {}
  register[params[:app]]['ip'] = params[:ip]
  register[params[:app]]['port'] = params[:port]
  register[params[:app]]['path'] = params[:path]
  register[params[:app]]['dpath'] = params[:dpath]
  register[params[:app]]['type'] = params[:type]
  register[params[:app]]['appkey'] = params[:appkey]
  save register
  { message: 'registered' }.to_json
end

get '/deregister' do
  headers\
    'Server' => 'monarch-proxy'
  content_type :json
  check_key params[:key]
  halt 500 unless params[:app]
  register = YAML.load_file 'register.yml'
  register.delete(params[:app])
  save register
  { message: 'deleted' }.to_json
end

get '/deploy' do
  headers\
    'Server' => 'monarch-proxy'
  content_type :json
  check_key params[:key]
  halt 500 unless params[:user]
  register = YAML.load_file 'register.yml'
  register.each do |_r, d|
    begin
      d['type'] == 'nologin' ? (login_type = '?isNoLogin=true&') : (login_type = '?')
      RestClient.get "http://#{d['ip']}:#{d['port']}/#{d['path']}#{login_type}user=#{params[:user]}&key=#{d['appkey']}"
    rescue RestClient::ExceptionWithResponse
    end
  end
  'Account created'
end

get '/destroy' do
  headers\
    'Server' => 'monarch-proxy'
  content_type :json
  check_key params[:key]
  halt 500 unless params[:user]
  register = YAML.load_file 'register.yml'
  register.each do |_r, d|
    begin
      RestClient.get "http://#{d['ip']}:#{d['port']}#{d['dpath']}?user=#{params[:user]}&key=#{d['appkey']}"
    rescue RestClient::ExceptionWithResponse
    end
  end
  'Account deleted'
end
