require 'net/http'

module Slack

  API_URI = URI("https://hooks.slack.com/services/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")

  def Slack.post(msg)
    Slack.send({ :text => msg })
    
    #res = Net::HTTP.start(Slack::API_URI.hostname, Slack::API_URI.port, :use_ssl => true) do |http|
    #  req = Net::HTTP::Post.new(Slack::API_URI, 'Content-Type' => 'application/json')
    #  req.body = { :text => msg }.to_json
    #  http.request(req)
    #rescue Exception => e
    #  puts "slack post failed"
    #end

  end

  def Slack.err(label, err)
    msg = "#{label}:\r\r`#{env['sinatra.error'].message}\r\r#{env['sinatra.error'].backtrace.join("\r")}`" )
    Slack.send({ :channel => 'website_errors', :text => msg })
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