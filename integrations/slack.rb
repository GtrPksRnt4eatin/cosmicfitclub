require 'net/http'

module Slack

  API_URI = URI("https://hooks.slack.com/services/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")

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
    res = Net::HTTP.start(Slack::API_URI.hostname, Slack::API_URI.port, :use_ssl => true) do |http|
      req = Net::HTTP::Post.new(Slack::API_URI, 'Content-Type' => 'application/json')
      req.body = body.to_json
      http.request(req)
    rescue Exception => e
      puts "slack post failed"
    end
  end

end