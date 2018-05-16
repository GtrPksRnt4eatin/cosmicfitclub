require 'rest-client'

require_relative '../auth/auth.rb'

class Door < Sinatra::Base

  enable :sessions

  register Sinatra::Auth

  post('/up', :auth=> 'door') do
    RestClient.patch( 'http://cosmicfitclub.ddns.net:5000/api/v1/pin/14', '{ "value": 0 }', :content_type => 'application/json' )
    sleep(0.5)
    RestClient.patch( 'http://cosmicfitclub.ddns.net:5000/api/v1/pin/14',  '{ "value": 1 }', :content_type => 'application/json' )
    Slack.post "#{Time.now.strftime("%m/%d/%Y %I:%M:%S %p")} Door Opened By #{customer.nil? ? "Unknown" : customer.name}"
  end

  post('/down', :auth=> 'door') do
    payload = { :value => params[:val].to_i == 1 ? 0 : 1 }.to_json
    RestClient.patch( 'http://cosmicfitclub.ddns.net:5000/api/v1/pin/18', payload , :content_type => 'application/json' )
  end

  post('/stop', :auth=> 'door') do
    RestClient.patch( 'http://cosmicfitclub.ddns.net:5000/api/v1/pin/15', { :value => 0 }.to_json, :content_type => 'application/json' ) 
    sleep(0.5)
    RestClient.patch( 'http://cosmicfitclub.ddns.net:5000/api/v1/pin/15', { :value => 1 }.to_json, :content_type => 'application/json' ) 
  end

end
