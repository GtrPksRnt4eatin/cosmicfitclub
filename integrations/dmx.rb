require 'uri'
require 'rest-client'

require_relative '../auth/auth.rb'

class Dmx < Sinatra::Base

  register Sinatra::Auth

  get('/device/:id') do
    RestClient.get( "http://cosmicloft.dyndns.org:91/device/#{params[:id]}", :content_type => 'application/json', :timeout => 3 )
  end

  post('/cmd') do
    path = "#{params['index']}/#{params[:capability]}/#{URI.encode_uri_component(params[:value])}"
    RestClient.get( "http://cosmicloft.dyndns.org:91/#{path}", :content_type => 'application/json', :timeout => 3 )
  end

end