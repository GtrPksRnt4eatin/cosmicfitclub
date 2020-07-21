require 'paypal-payouts-sdk'

module PayPalSDK
  @@environment = PayPal::LiveEnvironment.new(ENV['PAYPAL_ID'],ENV['PAYPAL_SECRET'])
  @@client = PayPal::PayPalHttpClient.new(@@environment) 
  define_singleton_method(:client) do
    @@client
  end

  def PayPalSDK::payout_batch_header 
    { recipient_type: 'EMAIL',
      email_message: 'SDK Payouts Test',
      note: 'testing testing testing',
      sender_batch_id: rand(36**8).to_s(36),
      email_subject: 'Test of Paypal Payout System'
    }
  end

  def PayPalSDK::payout_batch_item(arg)
    { receiver: arg[:recipient],
      amount: {
        currency: 'USD',
        value: '%.2f' % arg[:amount]
      },
      note: arg[:note],
      sender_item_id: rand(36**8).to_s(36)
    }
  end

  def PayPalSDK::payout_batch(items)
    body = {
      sender_batch_header: payout_batch_header,
      items: [
        items.map { |x| payout_batch_item(x) }
      ]
    }
    request = PaypalPayoutsSdk::Payouts::PayoutsPostRequest::new
    request.request_body(body) 
    begin
      response = client.execute(request)
      p response
      batch_id = response.result.batch_header.payout_batch_id
      return batch_id
    rescue PayPalHttp::HttpError => ioe
      puts ioe.status_code
      puts ioe.headers["debug_id"]
    end
  end
  puts
end

class PayPalRoutes < Sinatra::Base

  post '/webhooks' do 
  	data = JSON.parse request.body.read
  	Slack.webhook("PayPal Webhook: #{data['event_type']}", JSON.pretty_generate(data))
  end

end