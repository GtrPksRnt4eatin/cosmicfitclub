require 'sinatra/cross_origin'

require_relative '../../extensions/JwtAuth.rb'

class LocationRoutes < Sinatra::Base
  
  ################################### CONFIG ####################################

  register Sinatra::Auth
  use JwtAuth

  configure do
    enable :cross_origin
  end

  before do
    cache_control :no_store
    origin_ok = ['https://video.cosmicfitclub.com', 'https://localhost:3000'].include? request.env["HTTP_ORIGIN"]
    response.headers['Access-Control-Allow-Origin'] = request.env["HTTP_ORIGIN"] if origin_ok
    response.headers['Access-Control-Allow-Credentials'] = 'true'
  end

  ################################### CONFIG ####################################

  get '/all' do
    Location.all.to_json
  end

end