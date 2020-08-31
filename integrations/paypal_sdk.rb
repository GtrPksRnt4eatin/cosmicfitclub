require 'paypal-payouts-sdk'
require 'paypal-sdk-rest'

PayPal::SDK.configure(
  :mode => "live",
  :client_id => ENV['PAYPAL_ID'],
  :client_secret => ENV['PAYPAL_SECRET'],
  :ssl_options => {
    :ca_file => '/usr/lib/ssl/certs/ca-certificates.crt'
  }
)

module PayPalSDK
  include PayPal::SDK::REST

  @@environment = PayPal::LiveEnvironment.new(ENV['PAYPAL_ID'],ENV['PAYPAL_SECRET'])
  @@client = PayPal::PayPalHttpClient.new(@@environment)

  define_singleton_method(:client) do
    @@client
  end

  def PayPalSDK::list_transactions
    Payment.all(:count=>10)
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
      items: items.map { |x| payout_batch_item(x) }
    }
    request = PaypalPayoutsSdk::Payouts::PayoutsPostRequest::new
    request.request_body(body) 
    begin
      response = client.execute(request)
      batch_id = response.result.batch_header.payout_batch_id
      return batch_id
    rescue PayPalHttp::HttpError => ioe
      p ioe.result.message
      puts ioe.status_code
    end
  end
  puts
end