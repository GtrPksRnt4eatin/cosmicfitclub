require 'rest-client'

require_relative '../auth/auth.rb'

class Door < Sinatra::Base
  
  register Sinatra::Auth
 
  get('/email_link') do
    reservation = GroupReservation[ :tag => params[:tag] ] or return "Invalid Reservation Tag"
    if((reservation.start_time - 30.minutes) > Time.now) then return "This link will not work until #{(reservation.start_time - 30.minutes ).strftime("%m/%d/%Y %I:%M:%S %p")}" end
    if((reservation.end_time + 30.minutes)   < Time.now) then return "This link has expired as of #{(reservation.end_time + 30.minutes).strftime("%m/%d/%Y %I:%M:%S %p")}" end
    RestClient.get( 'http://loft.cosmicfitclub.com:86/cm?cmnd=Power%20On', :content_type => 'application/json', :timeout => 3 )
    sleep(15)
    RestClient.get( 'http://loft.cosmicfitclub.com:86/cm?cmnd=Power%20Off', :content_type => 'application/json', :timeout => 3 )
    return "The door has been opened and will remain open for 15 seconds."
  end
    
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

  post('/tag') do
    tag = NfcTag[ :value => params[:value] ] 
    tag or ( Slack.website_access "Tag Scanned: #{params[:value]}"; halt 401 )
    status = RestClient.get( 'http://66.108.37.62:86/cm?cmnd=Power', :content_type=>'application/json', :timeout=>1)
    status = JSON.parse(status)
    Slack.website_access "#{Time.now.strftime("%m/%d/%Y %I:%M:%S %p")} Door Tagged By #{tag.customer.name}"
    RestClient.get( 'http://66.108.37.62:86/cm?cmnd=Power%20On', :content_type => 'application/json', :timeout => 3 )
    sleep(8)
    RestClient.get( "http://66.108.37.62:86/cm?cmnd=Power%20#{status["POWER"].capitalize}", :content_type => 'application/json', :timeout => 3 )
    status 204
  end

end
