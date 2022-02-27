require 'net/http'

module Slack

  API_URI = URI(ENV["SLACK_WEBHOOK"])

  def Slack.post(msg)
    Slack.send({ :text => msg })
  end

  def Slack.website_access(msg)
    Slack.custom(msg,'website_access')
  end

  def Slack.website_scheduling(msg)
    Slack.custom(msg,'website_scheduling')
  end

  def Slack.website_purchases(msg)
    Slack.custom(msg,'website_purchases')
  end

  def Slack.loft(msg)
    Slack.custom(msg,'loft')
  end

  def Slack.custom(message, channel='website_notifications', attachment=nil)
    Slack.send({
      :channel     => channel,
      :text        => message,
      :mrkdwn      => true,
      :username    => 'cosmicdonut',
      :attachments => attachment.nil? ? [] : [ { "text": attachment, "mrkdwn_in": ["text"] } ]
    })
  end

  def Slack.webhook(label, body)
    msg = "#{label}:\r\r"
    Slack.send({ 
      :channel => 'website_notifications', 
      :text => msg, 
      :username => 'cosmicdonut', 
      :mrkdwn => true,     
      :attachments => [
        {   "text": body,
            "mrkdwn_in": ["text"]
        }
      ] 
    })
  end

  def Slack.raw_err(label, message)
    Slack.send({
      :channel => 'website_errors',
      :text => "#{label}: #{message}",
      :username => 'cosmicdonut'
    })
  end

  def Slack.err(label, err)
    msg = "#{label}:\r\r`#{err.message}\r\r`"
    Slack.send({ 
      :channel => 'website_errors', 
      :text => msg, 
      :username => 'cosmicdonut', 
      :mrkdwn => true,     
      :attachments => [
        {
            "title": "Exception",
            "text": "#{err.backtrace.join("\r")}",
            "mrkdwn_in": ["text"]
        }
      ] 
    })
  end

  def Slack.send(body)
    uri = URI('https://slack.com/api/chat.postMessage')
    res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) do |http|
      headers = {
        'Authorization' => 'Bearer ' + ENV["SLACK_TOKEN"],
        'Content-Type'  => 'application/json'
      }
      req = Net::HTTP::Post.new(Slack::API_URI, headers)
      req.body = body.to_json
      http.request(req)
    rescue Exception => e
      puts "slack post failed"
    end
  end

end