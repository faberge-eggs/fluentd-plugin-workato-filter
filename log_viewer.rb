require 'json'
require 'base64'
require 'sinatra'
require "sinatra/reloader"
require "sinatra/multi_route"
require 'slim'
require 'pry-byebug'

set :bind, '0.0.0.0'
set :environment, :development
set :logging, :dump_errors, :raise_errors

route :get, :post, '/' do
  halt slim :index, locals: { json: nil } unless params[:file]
  json = JSON.parse params[:file][:tempfile].read
  # data = Base64.decode64(json['rawData'])
  # error = JSON.parse json['errorMessage']
  json['errorMessage'] = JSON.parse json['errorMessage']
  data = JSON.parse Base64.decode64(json['rawData'])
  # error = json['errorMessage']

  slim :index, locals: { json: json, data: data }
end
