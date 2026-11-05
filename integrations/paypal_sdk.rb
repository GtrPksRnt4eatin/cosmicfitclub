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

  def PayPalSDK::normalize_range(start, finish)
    start_iso = start.iso8601 rescue Time.parse(start.to_s).iso8601
    finish_time = finish.is_a?(Time) ? finish : Time.parse(finish.to_s)
    finish_iso = (finish_time > Time.now) ? Time.now.iso8601 : finish_time.iso8601
    [start_iso, finish_iso]
  end

  def PayPalSDK::fetch_transactions_data(start, finish)
    start_iso, finish_iso = PayPalSDK::normalize_range(start, finish)
    api.get("v1/reporting/transactions", {
      :start_date => start_iso,
      :end_date => finish_iso,
      :fields => 'all',
      :page_size => 500
    })
  end

  def PayPalSDK::transactions_report(start, finish)
    data = PayPalSDK::fetch_transactions_data(start, finish)
    details = data && data['transaction_details'] ? data['transaction_details'] : []
    rows = details.map { |detail| PayPalSDK::transaction_row(detail) }.compact
    { data: data || {}, rows: rows }
  end

  def PayPalSDK::normalize_row_hash(item)
    return nil unless item.is_a?(Hash)

    transaction_info = item['transaction_info']
    return nil unless transaction_info

    payer_info = item['payer_info'] || {}
    trans_t = Time.parse(transaction_info['transaction_initiation_date'])
    has_payer = !!payer_info['payer_status']

    {
      :timestamp => trans_t.utc.iso8601,
      :date => trans_t.strftime("%m/%d/%Y"),
      :time => trans_t.strftime("%l:%M %P"),
      :name => has_payer ? payer_info.dig('payer_name', 'alternate_full_name').to_s : '',
      :email => has_payer ? payer_info['email_address'].to_s : '',
      :amount => transaction_info.dig('transaction_amount', 'value'),
      :fee => transaction_info['fee_amount'] ? transaction_info['fee_amount']['value'] : '',
      :status => transaction_info['transaction_status'],
      :note => transaction_info['transaction_note'],
      :id => transaction_info['transaction_id']
    }
  rescue
    nil
  end

  def PayPalSDK::row_array(row, numeric: true)
    return nil if row.nil?

    amount_value = numeric ? row[:amount].to_f : row[:amount]
    fee_value = if row[:fee].to_s.empty?
      numeric ? nil : ''
    else
      numeric ? row[:fee].to_f : row[:fee]
    end

    [
      row[:date],
      row[:time],
      row[:name],
      row[:email],
      amount_value,
      fee_value,
      row[:status],
      row[:note],
      row[:id]
    ]
  end

  def PayPalSDK::transaction_row(item)
    PayPalSDK::normalize_row_hash(item)
  rescue
    nil
  end

  def PayPalSDK::list_transactions(start,finish) 
    PayPalSDK::transactions_report(start, finish)[:rows]
  end

  def PayPalSDK::list_transactions_csv(start,finish)
    report = PayPalSDK::transactions_report(start, finish)
    data = report[:data]
    rows = report[:rows]

    csv = CSV.new("")
    csv << ["Account #", data['account_number']]
    csv << ["Start", Date.parse(data['start_date']).strftime("%m/%d/%Y")]
    csv << ["End", Date.parse(data['end_date']).strftime("%m/%d/%Y")]
    csv << []
    csv << ["Transaction Date", "Transaction Time", "Payer Name", "Transaction Amount", "Fee Amount", "Payer Email", "Transaction Status", "Transaction Note", "Transaction ID"]
    csv << []

    rows.each do |row|
      table_row = PayPalSDK::row_array(row, numeric: false)
      csv << table_row if table_row
    end

    csv.rewind
    csv
  end

  def PayPalSDK::month_slices(from_date, to_date)
    current = Date.new(from_date.year, from_date.month, 1)
    last = Date.new(to_date.year, to_date.month, 1)
    slices = []

    while current <= last
      month_start = [current, from_date].max
      month_end = [current.next_month.prev_day, to_date].min
      slices << [month_start, month_end]
      current = current.next_month
    end

    slices
  end

  def PayPalSDK::transactions_for_period(from, to)
    from_date = from.is_a?(Date) ? from : Date.parse(from.to_s)
    to_date = to.is_a?(Date) ? to : Date.parse(to.to_s)
    from_date, to_date = to_date, from_date if to_date < from_date

    transactions = []
    seen_ids = {}

    PayPalSDK::month_slices(from_date, to_date).each do |slice_start, slice_end|
      from_for_paypal = "#{slice_start} 00:00:00"
      to_for_paypal = "#{slice_end} 23:59:59"
      slice_transactions = PayPalSDK::list_transactions(from_for_paypal, to_for_paypal) || []

      slice_transactions.each do |row|
        row_id = row[:id].to_s
        dedupe_key = row_id.empty? ? "#{row[:date]}|#{row[:time]}|#{row[:amount]}|#{row[:email]}" : row_id
        next if seen_ids[dedupe_key]
        seen_ids[dedupe_key] = true
        transactions << row
      end
    end

    transactions.sort_by! do |row|
      begin
        row[:timestamp] ? Time.parse(row[:timestamp]) : Time.parse("#{row[:date]} #{row[:time]}")
      rescue
        Time.at(0)
      end
    end
    transactions
  rescue => e
    Slack.err('PayPal Transactions Period Error', e)
    []
  end

  def PayPalSDK::summary_cents_from_transactions(transactions)
    external = (transactions || []).select { |row| PayPalSDK::external_transaction?(row) }

    income_cents = external.sum do |row|
      amount_cents = PayPalSDK::amount_to_cents(row[:amount])
      amount_cents > 0 ? amount_cents : 0
    end

    amount_expense_cents = external.sum do |row|
      amount_cents = PayPalSDK::amount_to_cents(row[:amount])
      amount_cents < 0 ? amount_cents.abs : 0
    end

    fee_expense_cents = external.sum do |row|
      PayPalSDK::amount_to_cents(row[:fee]).abs
    end

    expense_cents = amount_expense_cents + fee_expense_cents

    {
      paypal_income_cents: income_cents,
      paypal_expenses_cents: expense_cents
    }
  end

  def PayPalSDK::monthly_transactions_payload(from, to)
    from_date = from.is_a?(Date) ? from : Date.parse(from.to_s)
    to_date = to.is_a?(Date) ? to : Date.parse(to.to_s)
    from_date, to_date = to_date, from_date if to_date < from_date

    all_transactions = PayPalSDK::transactions_for_period(from_date, to_date)

    months = PayPalSDK::month_slices(from_date, to_date).map do |slice_start, slice_end|
      month_transactions = all_transactions.select do |row|
        begin
          ts = row[:timestamp] ? Time.parse(row[:timestamp]) : Time.parse("#{row[:date]} #{row[:time]}")
          day = ts.to_date
          day >= slice_start && day <= slice_end
        rescue
          false
        end
      end

      summary = PayPalSDK::summary_cents_from_transactions(month_transactions)
      {
        start: slice_start,
        end: slice_end,
        transactions: month_transactions,
        paypal_income_cents: summary[:paypal_income_cents],
        paypal_expenses_cents: summary[:paypal_expenses_cents]
      }
    end

    { from: from_date, to: to_date, months: months }
  end

  def PayPalSDK::amount_to_cents(value)
    return 0 if value.nil?
    ((value.to_s.to_f) * 100.0).round
  end

  def PayPalSDK::external_transaction?(row)
    !row[:name].to_s.strip.empty?
  end

  def PayPalSDK::transactions_sheet_rows(from, to, payload=nil)
    payload ||= PayPalSDK::monthly_transactions_payload(from, to)

    rows = []
    rows << ['PayPal Transactions']
    rows << ['Period', "#{payload[:from]} to #{payload[:to]}"]
    rows << []

    payload[:months].each do |month|
      rows << [month[:start].strftime('%b %Y')]
      rows << ['Date', 'Time', 'Payer Name', 'Payer Email', 'Amount', 'Fee', 'Status', 'Note', 'Transaction ID']

      month[:transactions].each do |row|
        table_row = PayPalSDK::row_array(row, numeric: true)
        rows << table_row if table_row
      end

      rows << [
        'Income Subtotal (external only)',
        '',
        '',
        '',
        month[:paypal_income_cents].to_f / 100.0,
        '',
        '',
        '',
        ''
      ]

      rows << [
        'Expense Subtotal (external only)',
        '',
        '',
        '',
        '',
        month[:paypal_expenses_cents].to_f / 100.0,
        '',
        '',
        ''
      ]

      rows << []
    end

    rows
  rescue => e
    Slack.err('PayPal Transactions Sheet Error', e)
    [
      ['PayPal Transactions'],
      ['Period', "#{from} to #{to}"],
      [],
      ['Error', 'Unable to load PayPal transactions for this range']
    ]
  end

  def PayPalSDK::summary_cents(from, to)
    transactions = PayPalSDK::transactions_for_period(from, to)
    PayPalSDK::summary_cents_from_transactions(transactions)
  rescue => e
    Slack.err('PayPal Summary Error', e)
    { paypal_income_cents: 0, paypal_expenses_cents: 0 }
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