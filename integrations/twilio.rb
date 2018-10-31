require 'twilio-ruby'

def send_sms_to(msg,numbers)
  client = Twilio::REST::Client.new 'AC3ea86c47d6a22914d5bddff93f335dda', '6cbc0ac3e73eebb57311578021f5ba24'
  numbers.each do |num|
    client.api.account.messages.create({
      :from => '+13476700019',
      :to   => num,
      :body => msg
    })
  end
rescue Exception => e
  Slack.err("Twilio Error", e)
end

def send_sms(msg)	
  client = Twilio::REST::Client.new 'AC3ea86c47d6a22914d5bddff93f335dda', '6cbc0ac3e73eebb57311578021f5ba24'
  client.api.account.messages.create({
    :from => '+13476700019',
    :to => '201-280-6512',
    :body =>  "#{msg}"
  })
  client.api.account.messages.create({
    :from => '+13476700019',
    :to => '646-704-2405',
    :body =>  "#{msg}"
  })
  client.api.account.messages.create({
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
    Slack.webhook("Incoming Call From", "#{params[:From]}\r\n#{params[:CallerName]}\r\n#{params[:CallerCity]}, #{params[:CallerState]} #{params[:CallerZip]}")
    response = Twilio::TwiML::VoiceResponse.new
    response.redirect('/twilio/incoming2')
    response.to_s
  end

  post '/incoming2' do
  	content_type 'application/xml'
  	response = Twilio::TwiML::VoiceResponse.new
  	response.gather(input: 'dtmf', timeout: 4, num_digits: 1, action: 'https://cosmicfitclub.com/twilio/selection') do |gather|
  	  gather.say('Hi, Thanks for calling Cosmic Fit Club!')
  	  gather.say('Press One to speak with Joy about classes and personal training.')
  	  gather.say('Press Two to speak with Ben about the website, or billing issues.')
  	  gather.say('Press Three to speak with Donut.')
  	end
    response.redirect('/twilio/incoming2')
  	response.to_s
  rescue Exception => e
    Slack.err("Incoming Call Error:", e)
  end

  post '/selection' do
    content_type 'application/xml'
  	response = Twilio::TwiML::VoiceResponse.new
    case params[:Digits]
    when '1'
      Slack.post("Forwarding Call To Joy")
      response.say('Paging Joy Now. Please Wait.')
      response.dial(caller_id: '+13476700019') { |dial| dial.number '646-704-2405' }
      response.hangup
    when '2'
      Slack.post("Forwarding Call To Ben")
      response.say('Paging Ben Now. Please Wait.')
      response.dial(caller_id: '+13476700019') { |dial| dial.number '201-280-6512' }
      response.hangup
    when '3'
      Slack.post("Forwarding Call To Donut")
      response.say('Meow, Meow, Meow.')
      response.pause
      response.say('Purr. Purr. Meow.')
      response.pause
      response.say('Ack. Cough. Hairball.')
      response.pause
      response.say('Woof.. No, Wait.. I mean Meow Meow Meow. Roar!!')
      response.redirect('/twilio/incoming2')
    end
    response.to_s
  rescue Exception => e
    Slack.err("Call Forwarding Error:", e)
  end

end
