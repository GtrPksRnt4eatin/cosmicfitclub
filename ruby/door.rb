require 'rest-client'

require_relative '../auth/auth.rb'

class Door < Sinatra::Base
  
  register Sinatra::Auth
  
  post('/momentary', :auth=> 'door') do
    RestClient.get( 'http://66.108.37.62:86/cm?cmnd=Power%20On', :content_type => 'application/json', :timeout => 3 )
    Slack.website_access "#{Time.now.strftime("%m/%d/%Y %I:%M:%S %p")} Door Momentarily Opened By #{customer.nil? ? "Unknown" : customer.name}"
    sleep(10)
    RestClient.get( 'http://66.108.37.62:86/cm?cmnd=Power%20Off', :content_type => 'application/json', :timeout => 3 )
  end

  post('/open', :auth=> 'door') do
    RestClient.get( 'http://66.108.37.62:86/cm?cmnd=Power%20On', :content_type => 'application/json', :timeout => 3 )
    Slack.website_access "#{Time.now.strftime("%m/%d/%Y %I:%M:%S %p")} Door Opened By #{customer.nil? ? "Unknown" : customer.name}"
  end

  post('/close', :auth=> 'door') do
    RestClient.get( 'http://66.108.37.62:86/cm?cmnd=Power%20Off', :content_type => 'application/json', :timeout => 3 )
    Slack.website_access "#{Time.now.strftime("%m/%d/%Y %I:%M:%S %p")} Door Closed By #{customer.nil? ? "Unknown" : customer.name}"
  end
  
  get('/status', :auth=> 'door') do
    RestClient.get( 'http://66.108.37.62:86/cm?cmnd=Power', :content_type=>'application/json', :timeout=>1)
  end

end
