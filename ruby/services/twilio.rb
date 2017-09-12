require 'twilio-ruby'

$twilio_client

def send_sms(msg)	
  client = Twilio::REST::Client.new 'AC3ea86c47d6a22914d5bddff93f335dda', '6cbc0ac3e73eebb57311578021f5ba24'
  client.account.messages.create({
    :from => '+15162998588',
    :to => '201-280-6512',
    :body =>  "#{msg}"
  })
  client.account.messages.create({
    :from => '+15162998588',
    :to => '646-704-2405',
    :body =>  "#{msg}"
  })
rescue Exception => e
  puts e.message
  puts e.backtrace
end

class TwilioRoutes < Sinatra::Base

  get '/incoming' do
  	content_type 'appliction/xml'
  	response = Twilio::TwiML::VoiceResponse.new
  	response.say('Hi, Thanks for calling Cosmic Fit Club!')
  end

  post '/incoming' do
  	content_type 'appliction/xml'
  	response = Twilio::TwiML::VoiceResponse.new
  	response.say('Hi, Thanks for calling Cosmic Fit Club!')
  end

end
