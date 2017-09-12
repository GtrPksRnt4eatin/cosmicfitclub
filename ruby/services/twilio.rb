require 'twilio-ruby'

def send_sms(msg)	
  client = Twilio::REST::Client.new 'AC3ea86c47d6a22914d5bddff93f335dda', '6cbc0ac3e73eebb57311578021f5ba24'
  client.account.messages.create({
    :from => '+13476700019',
    :to => '201-280-6512',
    :body =>  "#{msg}"
  })
  client.account.messages.create({
    :from => '+13476700019',
    :to => '646-704-2405',
    :body =>  "#{msg}"
  })
  client.account.messages.create({
    :from => '+13476700019',
    :to => '917-642-1328',
    :body =>  "#{msg}"
  })
rescue Exception => e
  puts e.message
  puts e.backtrace
end

class TwilioRoutes < Sinatra::Base

  post '/incoming' do
  	content_type 'application/xml'
  	response = Twilio::TwiML::VoiceResponse.new
  	response.gather(input: 'dtmf', timeout: 3, num_digits: 1, action: 'http://cosmicfitclub.com/twilio/selection') do |gather|
  	  gather.say('Hi, Thanks for calling Cosmic Fit Club!')
  	  gather.say('Press One to speak with Joy about rentals and evening classes.')
  	  gather.say('Press Two to speak with Phil about Personal Training, Kids Classes, and morning classes.')
  	  gather.say('Press Three to speak with Ben about the website, or billing issues.')
  	  gather.say('Press Four to speak with Donut.')
  	end
  	response.say('We didn\'t receive any input. Goodbye!')
  	response.hangup
  	response.to_s
  end

  post '/selection' do
  	p request.body
  	response = Twilio::TwiML::VoiceResponse.new
    case params[:Digits]
    when '1'
      response.say('Paging Joy Now. Please Wait.')
      response.dial(caller_id: '+13476700019') { |dial| dial.number '646-704-2405' }
      response.hangup
    when '2'
      response.say('Paging Phil Now. Please Wait.')
      response.dial(caller_id: '+13476700019') { |dial| dial.number '917-642-1328' }
      response.hangup
    when '3'
      response.say('Paging Ben Now. Please Wait.')
      response.dial(caller_id: '+13476700019') { |dial| dial.number '201-280-6512' }
      response.hangup
    when '4'
      response.say('Meow, Meow, Meow, Purr, Purr, Meow, ack, cough, hairball')
      response.hangup
    end
    response.to_s
  end

end
