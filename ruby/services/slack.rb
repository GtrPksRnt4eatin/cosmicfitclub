require 'net/http'

module Slack

  API_URI = URI("https://hooks.slack.com/services/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")

  def Slack.post(msg)	
    
    res = Net::HTTP.start(Slack::API_URI.hostname, Slack::API_URI.port, :use_ssl => true) do |http|
      req = Net::HTTP::Post.new(Slack::API_URI, 'Content-Type' => 'application/json')
      req.body = { :text => msg }.to_json
      http.request(req)
    rescue Exception => e
      puts "slack post failed"
    end

  end

end