require 'rest-client'

require_relative '../auth/auth.rb'

class Door < Sinatra::Base
  
  register Sinatra::Auth

  post('/up', :auth=> 'door') do
    RestClient.patch( 'http://cosmicfitclub.ddns.net:5000/api/v1/pin/26', '{ "value": 1 }', :content_type => 'application/json', :timeout => 3 )
    sleep(0.5)
    RestClient.patch( 'http://cosmicfitclub.ddns.net:5000/api/v1/pin/26',  '{ "value": 0 }', :content_type => 'application/json', :timeout => 3 )
    Slack.website_access "#{Time.now.strftime("%m/%d/%Y %I:%M:%S %p")} Door Opened By #{customer.nil? ? "Unknown" : customer.name}"
  end

  post('/down', :auth=> 'door') do
    payload = { :value => params[:val].to_i }.to_json
    RestClient.patch( 'http://cosmicfitclub.ddns.net:5000/api/v1/pin/6', payload , :content_type => 'application/json', :timeout => 3 )
  end

  post('/stop', :auth=> 'door') do
    RestClient.patch( 'http://cosmicfitclub.ddns.net:5000/api/v1/pin/22', { :value => 1 }.to_json, :content_type => 'application/json', :timeout => 3 ) 
    sleep(0.5)
    RestClient.patch( 'http://cosmicfitclub.ddns.net:5000/api/v1/pin/22', { :value => 0 }.to_json, :content_type => 'application/json', :timeout => 3 ) 
  end

  post('/open', :auth=> 'door') do
    RestClient.get( 'http://72.231.24.250:86/cm?cmnd=Power%20On', :content_type => 'application/json', :timeout => 3 )
  end

  post('/close', :auth=> 'door') do
    RestClient.get( 'http://72.231.24.250:86/cm?cmnd=Power%20Off', :content_type => 'application/json', :timeout => 3 )
  end

  get('/status', :auth=> 'door') do
    RestClient.get( 'http://72.231.24.250:86/cm?cmnd=Power', :content_type=>'application/json', :timeout=>3)
  end

end
