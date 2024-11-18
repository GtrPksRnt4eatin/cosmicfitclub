require 'rest-client'

class NfcTagRoutes < Sinatra::Base

  post '/' do
  	tag = NfcTag[ :value => params[:value] ]
    puts params[:value]
    puts tag
    if (tag && tag.customer)
      RestClient.get( 'http://66.108.37.62:86/cm?cmnd=Power%20On', :content_type => 'application/json', :timeout => 3 )
      Slack.website_access "#{Time.now.strftime("%m/%d/%Y %I:%M:%S %p")} Door Tagged Open By #{tag.customer.name}"
      sleep(10)
      RestClient.get( 'http://66.108.37.62:86/cm?cmnd=Power%20Off', :content_type => 'application/json', :timeout => 3 )
    end
    tag.to_json
  end

end