require 'twilio-ruby'

def send_sms_to(msg, numbers, include_optout = true)
  client = Twilio::REST::Client.new(ENV['TWILIO_SID'], ENV['TWILIO_AUTH_TOKEN'])
  
  # Append opt-out language if not already present (required for A2P compliance)
  if include_optout && !msg.downcase.include?('stop')
    msg += " Reply STOP to opt out."
  end
  
  numbers.each do |num|
    client.messages.create(
      from: '+13476700019',
      to: num,
      body: msg
    )
  end
rescue Exception => e
  Slack.err("Twilio Error", e)
end

def send_sms(msg)	
  client = Twilio::REST::Client.new(ENV['TWILIO_SID'], ENV['TWILIO_AUTH_TOKEN'])
  client.messages.create(
    :from => '+13476700019',
    :to => '201-280-6512',
    :body =>  "#{msg}"
  )
  client.messages.create(
    :from => '+13476700019',
    :to => '646-704-2405',
    :body =>  "#{msg}"
  )
  client.messages.create(
    :from => '+13476700019',
    :to => '917-642-1328',
    :body =>  "#{msg}"
  )
rescue Exception => e
  puts e.message
  puts e.backtrace
end

class TwilioRoutes < Sinatra::Base

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  register Sinatra::Auth
  use JwtAuth

  set :root, File.expand_path('../../site', __FILE__)

  configure do
    enable :cross_origin
  end

  before do
    response.headers['Access-Control-Allow-Origin'] = request.env["HTTP_ORIGIN"]
    response.headers['Access-Control-Allow-Credentials'] = 'true'
  end

  # SMS Opt-In/Out Management
  
  get '/opt-in' do
    render_page :sms_opt_in
  end
  
  get '/status', :jwt_logged_in => true do
    content_type :json
    custy = customer
    {
      opted_in: custy.sms_opted_in?,
      opt_in_date: custy.sms_opt_in_date,
      phone: custy.phone
    }.to_json
  end
  
  post '/opt-in', :jwt_logged_in => true do
    content_type :json
    custy = customer
    phone = params[:phone]
    
    halt(400, { error: 'Phone number required' }.to_json) unless phone
    
    custy.opt_in_to_sms(phone)
    Slack.post("#{custy.name} (#{custy.email}) opted in to SMS notifications")
    
    {
      success: true,
      opted_in: true,
      opt_in_date: custy.sms_opt_in_date
    }.to_json
  rescue => e
    Slack.err("SMS Opt-In Error", e)
    halt(500, { error: 'Failed to opt in' }.to_json)
  end
  
  post '/opt-out', :jwt_logged_in => true do
    content_type :json
    custy = customer
    
    custy.opt_out_of_sms
    Slack.post("#{custy.name} (#{custy.email}) opted out of SMS notifications")
    
    {
      success: true,
      opted_in: false
    }.to_json
  rescue => e
    Slack.err("SMS Opt-Out Error", e)
    halt(500, { error: 'Failed to opt out' }.to_json)
  end
  
  # Handle incoming SMS messages (for STOP/START/HELP keywords)
  post '/incoming_sms' do
    content_type 'text/xml'
    
    from_number = params['From']
    message_body = params['Body'].to_s.strip.upcase
    
    customer = Customer.find_by_phone(from_number)
    
    response = Twilio::TwiML::MessagingResponse.new
    
    if message_body =~ /^(STOP|UNSUBSCRIBE|CANCEL|END|QUIT)$/
      if customer
        customer.opt_out_of_sms
        Slack.post("#{customer.name} opted out via SMS keyword")
      end
      # Twilio handles STOP automatically, but we can add custom response
      
    elsif message_body =~ /^(START|UNSTOP|SUBSCRIBE|YES)$/
      if customer
        customer.opt_in_to_sms(from_number)
        response.message("You're subscribed to Cosmic Fit Club SMS! Reply STOP to unsubscribe.")
        Slack.post("#{customer.name} opted in via SMS keyword")
      else
        response.message("Visit cosmicfitclub.com/sms/opt-in to subscribe to our notifications.")
      end
      
    elsif message_body =~ /^HELP$/
      response.message("Cosmic Fit Club SMS: Reply STOP to unsubscribe. For support, call (347) 670-0019 or email info@cosmicfitclub.com")
      
    else
      # Forward unknown messages to Slack
      custy_name = customer ? customer.name : "Unknown"
      Slack.custom("SMS from #{custy_name}: #{message_body}", 'text_messages', "From: #{from_number}")
      response.message("Thanks for your message! We'll get back to you soon. For immediate assistance, call (347) 670-0019.")
    end
    
    response.to_s
  rescue => e
    Slack.err("Incoming SMS Error", e)
    response = Twilio::TwiML::MessagingResponse.new
    response.message("We're experiencing technical difficulties. Please call (347) 670-0019 for assistance.")
    response.to_s
  end

  # Voice call routes
  
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
