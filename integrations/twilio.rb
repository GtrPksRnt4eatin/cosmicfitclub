require 'twilio-ruby'

def send_sms_to(msg,numbers)
  client = Twilio::REST::Client.new ENV['TWILIO_SID'], ENV['TWILIO_AUTH_TOKEN']
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
  client = Twilio::REST::Client.new ENV['TWILIO_SID'], ENV['TWILIO_AUTH_TOKEN']
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

  configure do
    enable :cross_origin
  end

  before do
    response.headers['Access-Control-Allow-Origin'] = request.env["HTTP_ORIGIN"]
    response.headers['Access-Control-Allow-Credentials'] = 'true'
  end

  post '/incoming' do
    num = /\+(\d)(\d\d\d)(\d\d\d)(\d\d\d\d)/.match(params[:From])
    num = num ? num[1..4].join('-') : params[:From]
    Slack.custom("Incoming Call", "call_logs","#{params[:CallerName]}\r\n#{num}\r\n#{params[:CallerCity]}, #{params[:CallerState]} #{params[:CallerZip]}")
    response = Twilio::TwiML::VoiceResponse.new
    response.redirect('/twilio/incoming2')
    response.to_s
  end

  post '/incoming2' do
  	content_type 'application/xml'
  	response = Twilio::TwiML::VoiceResponse.new
    response.dial(caller_id: num) { |dial| dial.number '201-280-6512' }
    #response.hangup
    #return response.to_s
  	response.gather(input: 'dtmf', timeout: 4, num_digits: 1, action: 'https://cosmicfitclub.com/twilio/selection') do |gather|
  	  gather.say(message: 'Hi, Thanks for calling Cosmic Fit Club!')
  	  gather.say(message: 'Press One to speak with Joy about classes and personal training.')
  	  gather.say(message: 'Press Two to speak with Ben about the website, or billing issues.')
  	  gather.say(message: 'Press Three to speak with Donut.')
  	end
    response.redirect('/twilio/incoming2')
  	response.to_s
  rescue Exception => e
    Slack.err("Incoming Call Error:", e)
  end

  post '/selection' do
    content_type 'application/xml'
  	response = Twilio::TwiML::VoiceResponse.new
    num = /\+(\d)(\d\d\d)(\d\d\d)(\d\d\d\d)/.match(params[:From])
    num = num ? num[1..4].join('-') : params[:From]
    case params[:Digits]
    when '1'
      Slack.custom("Forwarding Call To Joy", "call_logs")
      response.say(message: 'Paging Joy Now. Please Wait.')
      response.dial(caller_id: num) { |dial| dial.number '917-900-6498' }
      #response.dial(caller_id: '+13476700019') { |dial| dial.number '646-704-2405' }
      response.hangup
    when '2'
      Slack.custom("Forwarding Call To Ben", "call_logs")
      response.say(message: 'Paging Ben Now. Please Wait.')
      response.dial(caller_id: num) { |dial| dial.number '201-280-6512' }
      response.hangup
    when '3'
      Slack.custom("Forwarding Call To Donut", "call_logs")
      response.say(message: 'Meow, Meow, Meow.')
      response.pause
      response.say(message: 'Purr. Purr. Meow.')
      response.pause
      response.say(message: 'Ack. Cough. Hairball.')
      response.pause
      response.say(message: 'Woof.. No, Wait.. I mean Meow Meow Meow. Roar!!')
      response.redirect('/twilio/incoming2')
    end
    response.to_s
  rescue Exception => e
    Slack.err("Call Forwarding Error:", e)
  end

end
