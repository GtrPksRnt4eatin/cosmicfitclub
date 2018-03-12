require 'net/http'

module Slack

  API_URI = URI("https://hooks.slack.com/services/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")

  def Slack.post(msg)	
    req = Net::HTTP::Post.new(Slack::API_URI)
    req.body = { :text => msg }.to_json
    req.content_type = 'application/json'

    res = Net::HTTP.start(Slack::API_URI.hostname, Slack::API_URI.port) do |http|
      http.request(req)
    end

    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      p "Slack Message Posted"
    else
      p res.value
      p res
    end

  end

end