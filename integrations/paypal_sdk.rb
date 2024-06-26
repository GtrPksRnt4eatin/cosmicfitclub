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

  def PayPalSDK::list_transactions(start,finish) 
    start  = start.iso8601 rescue Time.parse(start).iso8601
    finish = ( finish.is_a? Time ) ? finish : Time.parse(finish)
    finish = ( finish > Time.now ) ? Time.now.iso8601 : finish.iso8601

    data = api.get("v1/reporting/transactions", { :start_date=> start, :end_date=> finish, :fields=>'all', :page_size=>500 } )

    data['transaction_details'].map do |t|
      trans_t = Time.parse(t['transaction_info']['transaction_initiation_date'])
      { :date   => trans_t.strftime("%m/%d/%Y"),
        :time   => trans_t.strftime("%l:%M %P"),
        :name   => t['payer_info']['payer_status'] ? t['payer_info']['payer_name']['alternate_full_name'] : '',
        :email  => t['payer_info']['payer_status'] ? t['payer_info']['email_address'] : '',
        :amount => t['transaction_info']['transaction_amount']['value'],
        :fee    => t['transaction_info']['fee_amount'] ? t['transaction_info']['fee_amount']['value'] : '',
        :status => t['transaction_info']['transaction_status'],
        :note   => t['transaction_info']['transaction_note'],
        :id     => t['transaction_info']['transaction_id']
      }
    end

  end

  def PayPalSDK::list_transactions_csv(start,finish)
    start  = start.iso8601 rescue Time.parse(start).iso8601
    finish = ( finish.is_a? Time ) ? finish : Time.parse(finish)
    finish = ( finish > Time.now ) ? Time.now.iso8601 : finish.iso8601

    data = api.get("v1/reporting/transactions", { :start_date=> start, :end_date=> finish, :fields=>'all', :page_size=>500 } )
    csv = CSV.new("")
    csv << ["Account #", data['account_number']]
    csv << ["Start", Date.parse(data['start_date']).strftime("%m/%d/%Y")]
    csv << ["End", Date.parse(data['end_date']).strftime("%m/%d/%Y")]
    csv << []
    csv << [ "Transaction Date", "Transaction Time", "Payer Name", "Transaction Amount", "Fee Amount", "Payer Email", "Transaction Status", "Transaction Note", "Transaction ID" ]
    csv << []
    data['transaction_details'].each do |t|
      trans_t = Time.parse(t['transaction_info']['transaction_initiation_date'])
      csv << [ 
        trans_t.strftime("%m/%d/%Y"),
        trans_t.strftime("%l:%M %P"),
        t['payer_info']['payer_status'] ? t['payer_info']['payer_name']['alternate_full_name'] : '',
        t['transaction_info']['transaction_amount']['value'],
        t['transaction_info']['fee_amount'] ? t['transaction_info']['fee_amount']['value'] : '',
        t['payer_info']['payer_status'] ? t['payer_info']['email_address'] : '',
        t['transaction_info']['transaction_status'],
        t['transaction_info']['transaction_note'],
        t['transaction_info']['transaction_id']
      ]
    end
    csv.rewind
    csv
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

end