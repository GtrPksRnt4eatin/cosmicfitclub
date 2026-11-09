require 'google/apis/sheets_v4'
require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'
require 'stringio'
require 'securerandom'
require 'tmpdir'

module Sheets

  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'Other client 1'
  CREDENTIALS_PATH = File.join(File.dirname(__FILE__), "tokens.yaml")
  SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS

  def Sheets.authorize
    FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))
    client_id = Google::Auth::ClientId.from_hash(JSON.parse(ENV['SHEETS_SECRET']))
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    authorizer.get_credentials(user_id)
  end

  def Sheets.read_sheet
    spreadsheet_id = '1XckfZT_IRPZ43VCadw8yiQzUN4Xv5eh8IWbFI01ZLKE'
    range = 'A2:B30'
    retries = 0
    begin
      sheets, _drive = Sheets::get_service2
      response = sheets.get_spreadsheet_values(spreadsheet_id, range)
      response.values.map! { |val| { :question => val[0], :answer => val[1] } }
      response.values
    rescue Google::Apis::ServerError => e
      retries += 1
      if retries <= 3
        sleep(retries * 2)
        retry
      end
      Slack.err('FAQ Sheets Error', e)
      []
    rescue => e
      Slack.err('FAQ Sheets Error', e)
      []
    end
  end

  def Sheets.create(name)
    sheets = Sheets::get_service or return
    request_body = Google::Apis::SheetsV4::Spreadsheet.new
    sheets.create_spreadsheet(request_body)
  end

  def Sheets::get_service
    sheets = Google::Apis::SheetsV4::SheetsService.new
    sheets.client_options.application_name = APPLICATION_NAME
    sheets.authorization = Sheets.authorize
    sheets.authorization.nil? ? nil : sheets
  end

#################################################################################

  def Sheets::get_service2
    io = StringIO.new ENV['GOOGLE_SERVICE']
    scopes = [
      Google::Apis::DriveV3::AUTH_DRIVE,
      Google::Apis::SheetsV4::AUTH_SPREADSHEETS
    ]
    creds = Google::Auth::ServiceAccountCredentials.make_creds( json_key_io: io, scope: scopes )
    creds.fetch_access_token! if creds.respond_to?(:fetch_access_token!)

    sheets = Google::Apis::SheetsV4::SheetsService.new
    sheets.client_options.application_name = APPLICATION_NAME
    sheets.authorization = creds

    drive = Google::Apis::DriveV3::DriveService.new
    drive.client_options.application_name = APPLICATION_NAME
    drive.authorization = creds

    return sheets, drive
  end

  def Sheets::create_event_sheet(event_id)
    evt = Event[event_id] or return false
    title = evt.starttime.strftime("%Y-%m-%d [\##{evt.id}] #{evt.name}")
    sheets, drive = Sheets::get_service2
    folder_id = "1gEYA96NDJcToN_bJQ0_OpluI-ISYHyVg"

    metadata = {
      name: title,
      mime_type: 'application/vnd.google-apps.spreadsheet',
      parents: [folder_id]
    }
    
    file = drive.create_file( metadata, fields: 'id, webViewLink, web_view_link' )
    sheet_id = file.id

    # rename default sheet to 'Accounting' and populate
    batch_req = Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new(
      requests: [
        {
          update_sheet_properties: {
            properties: { sheet_id: 0, title: "Accounting" },
            fields: "title"
          },
        }
      ]
    )
    sheets.batch_update_spreadsheet(sheet_id, batch_req)

    values = Google::Apis::SheetsV4::ValueRange.new(values: evt.accounting_arr)
    sheets.update_spreadsheet_value(sheet_id, "Accounting!A1", values, value_input_option: 'USER_ENTERED')

    # add 'Attendance' sheet and populate
    add_sheet_req = Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new(
      requests: [
        {
          add_sheet: { properties: { title: "Attendance" }
        } }
      ]
    )
    sheets.batch_update_spreadsheet(sheet_id, add_sheet_req)

    values2 = Google::Apis::SheetsV4::ValueRange.new(values: evt.attendance_arr)
    sheets.update_spreadsheet_value(sheet_id, "Attendance!A1", values2, value_input_option: 'USER_ENTERED')

    return file.web_view_link || file.webViewLink
  end
  
  def Sheets::create_payroll_sheet(from,to)
    title = "#{from} to #{to}"
    sheets, drive = Sheets::get_service2
    folder_id = "1xFj5h7TuijiksYvmvu2rqjgtOqaHnyeJ"

    metadata = {
      name: title,
      mime_type: 'application/vnd.google-apps.spreadsheet',
      parents: [folder_id]
    }

    file = drive.create_file( metadata, fields: 'id, webViewLink, web_view_link' )
    sheet_id = file.id

    batch_req = Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new(
      requests: [
        {
          update_sheet_properties: { properties: { sheet_id: 0, title: "Payroll" },
            fields: "title"
          },
        }
      ]
    )
    sheets.batch_update_spreadsheet(sheet_id, batch_req)

    values = Google::Apis::SheetsV4::ValueRange.new(values: Staff::payroll_csv(from,to).to_a)
    sheets.update_spreadsheet_value(sheet_id, "Payroll!A1", values, value_input_option: 'USER_ENTERED')
    return file.web_view_link || file.webViewLink
  end
  
  def Sheets::create_sheet(drive, title, folder_id)
    metadata = {
      name: title,
      mime_type: 'application/vnd.google-apps.spreadsheet',
      parents: [folder_id]
    }
    file = drive.create_file( metadata, fields: 'id, webViewLink, web_view_link' )
    return file
  end

  def Sheets::add_sheet(sheets, sheet_id, sheet_name)
    batch_req = Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new(
      requests: [
        {
          add_sheet: { properties: { title: sheet_name }
        } }
      ]
    )
    sheets.batch_update_spreadsheet(sheet_id, batch_req)
  end

  def Sheets::rename_sheet(sheets, sheet_id, index, new_title)
    batch_req = Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new(
      requests: [
        {
          update_sheet_properties: {
            properties: { sheet_id: index, title: new_title },
            fields: "title"
          },
        }
      ]
    )
    sheets.batch_update_spreadsheet(sheet_id, batch_req)
  end

  def Sheets::fill_sheet(sheets, sheet_id, sheet_name, arr)
    values = Google::Apis::SheetsV4::ValueRange.new(values: arr)
    range = "#{sheet_name}!A1"
    sheets.update_spreadsheet_value(sheet_id, range, values, value_input_option: 'USER_ENTERED')
  end

  def Sheets::create_PNL_sheet(year)
    sheets, drive = Sheets::get_service2

    title = "#{year} Stripe Transactions"
    file = Sheets::create_sheet(drive, title, "1RvnAXjk20LdCrv6AunMWfhzLb81T-_9n")
    Sheets::rename_sheet(sheets, file.id, 0, "Jan")
    
    (1..12).each do |month|
      start = Date.new(year, month, 1)
      finish = start.next_month.prev_day
      sheet_name = start.strftime("%b")
      
      Sheets::add_sheet(sheets, file.id, sheet_name) unless month == 1
      values = StripeMethods::get_transactions(start.to_s, finish.to_s)
      Sheets::fill_sheet(sheets, file.id, sheet_name, values)
    end

    return file.web_view_link || file.webViewLink
  end

  def Sheets::money(cents)
    "$ %.2f" % (cents.to_f / 100.0)
  end

  def Sheets::monthly_pnl_rows(report)
    s = report[:summary]
    from = report[:from]
    to = report[:to]

    [
      ['Stripe P&L Summary'],
      ['Period', "#{from} to #{to}"],
      [],
      ['Metric', 'Amount'],
      ['Gross Sales (Charges)', Sheets::money(s[:gross_sales_cents])],
      ['Refunds', Sheets::money(s[:refunds_cents])],
      ['Disputes/Reversals', Sheets::money(s[:disputes_cents])],
      ['Adjustments/Reserves', Sheets::money(s[:adjustments_cents])],
      ['Stripe Fees', Sheets::money(s[:fees_cents])],
      ['Transfers', Sheets::money(s[:transfers_cents])],
      ['Payouts', Sheets::money(s[:payouts_cents])],
      [],
      ['Net Stripe Activity', Sheets::money(s[:net_cents])]
    ]
  end

  def Sheets::monthly_transaction_rows(report)
    sections = [
      'Class Purchases',
      'Point Rentals',
      'Packages',
      'Invoices',
      'Fees',
      'Transfers',
      'Other'
    ]

    rows = [["Stripe Transactions"]]

    by_section = report[:transactions].group_by { |row| row[:section] }

    transfer_recipient = lambda do |row|
      StripeMethods::transfer_recipient_from_description(row[:description])
    end

    sections.each do |section|
      txns = by_section[section] || []
      txns = if section == 'Transfers'
        txns.sort_by do |row|
          recipient_key = transfer_recipient.call(row).downcase
          [recipient_key, row[:created]]
        end
      else
        txns.sort_by { |row| row[:created] }
      end
      next if txns.empty?

      subtotal_amount = txns.sum { |row| row[:amount_cents] }
      subtotal_fee = txns.sum { |row| row[:fee_cents] }
      subtotal_net = txns.sum { |row| row[:net_cents] }

      rows << []
      rows << [section]
      rows << ["Time", "Type", "Payment Type", "Description", "Amount", "Fee", "Net", "Currency", "ID", "Source"]

      if section == 'Transfers'
        grouped = txns.group_by { |row| transfer_recipient.call(row) }
        grouped.keys.sort.each do |recipient|
          recipient_rows = grouped[recipient].sort_by { |row| row[:created] }
          recipient_amount = recipient_rows.sum { |row| row[:amount_cents] }
          recipient_fee = recipient_rows.sum { |row| row[:fee_cents] }
          recipient_net = recipient_rows.sum { |row| row[:net_cents] }

          rows << []
          rows << ["Recipient: #{recipient}"]

          recipient_rows.each do |row|
            rows << [
              row[:created].strftime('%Y-%m-%d %H:%M:%S'),
              row[:type],
              row[:payment_type].to_s,
              row[:description],
              row[:amount_cents].to_f / 100.0,
              row[:fee_cents].to_f / 100.0,
              row[:net_cents].to_f / 100.0,
              row[:currency],
              row[:id],
              row[:source]
            ]
          end

          rows << [
            "Recipient Subtotal",
            "",
            "",
            "",
            recipient_amount.to_f / 100.0,
            recipient_fee.to_f / 100.0,
            recipient_net.to_f / 100.0,
            "",
            "",
            ""
          ]
        end
      else
        txns.each do |row|
          rows << [
            row[:created].strftime('%Y-%m-%d %H:%M:%S'),
            row[:type],
            row[:payment_type].to_s,
            row[:description],
            row[:amount_cents].to_f / 100.0,
            row[:fee_cents].to_f / 100.0,
            row[:net_cents].to_f / 100.0,
            row[:currency],
            row[:id],
            row[:source]
          ]
        end
      end

      rows << [
        "Subtotal",
        "",
        "",
        "",
        subtotal_amount.to_f / 100.0,
        subtotal_fee.to_f / 100.0,
        subtotal_net.to_f / 100.0,
        "",
        "",
        ""
      ]
    end

    rows
  end

  def Sheets::period_summary_row(label, key, month_metrics, period_metrics)
    values = month_metrics.map do |metrics|
      cents = StripeMethods::metrics_value(metrics, key)
      cents.nil? ? nil : (cents.to_f / 100.0)
    end

    total_cents = StripeMethods::metrics_value(period_metrics, key)
    total_value = total_cents.nil? ? nil : (total_cents.to_f / 100.0)

    [label, ""] + values + ["", total_value]
  end

  def Sheets::aggregate_period_metrics(month_metrics)
    totals = {
      class_payments_cents: 0,
      point_rentals_cents: 0,
      packages_cents: 0,
      event_tickets_cents: 0,
      room_rentals_cents: 0,
      paypal_income_cents: 0,
      paypal_expenses_cents: 0,
      refunds_cents: 0,
      stripe_fees_cents: 0,
      transfer_totals_cents: Hash.new(0)
    }

    month_metrics.each do |metrics|
      totals[:class_payments_cents] += metrics[:class_payments_cents].to_i
      totals[:point_rentals_cents] += metrics[:point_rentals_cents].to_i
      totals[:packages_cents] += metrics[:packages_cents].to_i
      totals[:event_tickets_cents] += metrics[:event_tickets_cents].to_i
      totals[:room_rentals_cents] += metrics[:room_rentals_cents].to_i
      totals[:paypal_income_cents] += metrics[:paypal_income_cents].to_i
      totals[:paypal_expenses_cents] += metrics[:paypal_expenses_cents].to_i
      totals[:refunds_cents] += metrics[:refunds_cents].to_i
      totals[:stripe_fees_cents] += metrics[:stripe_fees_cents].to_i
      metrics[:transfer_totals_cents].each do |recipient, amount|
        totals[:transfer_totals_cents][recipient] += amount.to_i
      end
    end

    totals
  end

  def Sheets::chase_expenses_by_month_for_mask(mask_suffix, period_start, period_end)
    account = PlaidIntegration.account_by_mask(mask_suffix)
    return {} if account.nil?

    rows = PlaidIntegration.transactions(
      access_token: account['access_token'],
      start_date: period_start,
      end_date: period_end
    ).select { |row| row[:account_id].to_s == account['account_id'].to_s }

    grouped = Hash.new(0)

    rows.each do |row|
      merchant = row[:merchant_name].to_s
      description = row[:description].to_s
      next if merchant.match?(/paypal/i) || description.match?(/paypal/i)

      amount = if row[:normalized_amount].nil?
        (row[:amount].to_f * -1.0).round(2)
      else
        row[:normalized_amount].to_f
      end
      next unless amount < 0

      month_key = begin
        Date.parse(row[:date].to_s).strftime('%Y-%m')
      rescue
        row[:date].to_s[0, 7]
      end
      grouped[month_key] += ((amount.abs) * 100.0).round
    end

    grouped
  rescue => e
    Slack.err('Chase Expenses Aggregation Error', e)
    {}
  end

  def Sheets::loft_metrics_by_month_for_mask(mask_suffix, period_start, period_end)
    account = PlaidIntegration.account_by_mask(mask_suffix)
    return {} if account.nil?

    rows = PlaidIntegration.transactions(
      access_token: account['access_token'],
      start_date: period_start,
      end_date: period_end
    ).select { |row| row[:account_id].to_s == account['account_id'].to_s }

    grouped = Hash.new do |hash, key|
      hash[key] = {
        income_cents: 0,
        expense_cents: 0,
        category_totals_cents: Hash.new(0)
      }
    end

    rows.each do |row|
      month_key = begin
        Date.parse(row[:date].to_s).strftime('%Y-%m')
      rescue
        row[:date].to_s[0, 7]
      end

      amount = if row[:normalized_amount].nil?
        (row[:amount].to_f * -1.0).round(2)
      else
        row[:normalized_amount].to_f
      end
      amount_cents = (amount * 100.0).round

      category = PlaidIntegration.loft_category(row)
      grouped[month_key][:category_totals_cents][category] += amount_cents

      if amount_cents >= 0
        grouped[month_key][:income_cents] += amount_cents
      else
        grouped[month_key][:expense_cents] += amount_cents.abs
      end
    end

    grouped
  rescue => e
    Slack.err('Loft Metrics Aggregation Error', e)
    {}
  end

  def Sheets::period_summary_rows(month_ranges, month_reports, period_start, period_end, paypal_payload=nil, chase_expenses_by_month=nil)
    month_labels = month_ranges.map { |month_start, _month_end| month_start.strftime('%b').upcase }
    paypal_payload ||= PayPalSDK::monthly_transactions_payload(period_start, period_end)
    chase_expenses_by_month ||= {}
    paypal_by_month = {}
    paypal_payload[:months].each do |month|
      paypal_by_month[month[:start].strftime('%Y-%m')] = {
        paypal_income_cents: month[:paypal_income_cents].to_i,
        paypal_expenses_cents: month[:paypal_expenses_cents].to_i
      }
    end

    month_metrics = month_reports.each_with_index.map do |report, index|
      month_start, _month_end = month_ranges[index]
      paypal_metrics = paypal_by_month[month_start.strftime('%Y-%m')] || { paypal_income_cents: 0, paypal_expenses_cents: 0 }
      chase_metrics = { chase_expenses_cents: chase_expenses_by_month[month_start.strftime('%Y-%m')].to_i }
      StripeMethods::period_metrics(report).merge(paypal_metrics).merge(chase_metrics)
    end
    period_metrics = Sheets::aggregate_period_metrics(month_metrics)

    other_recipients = period_metrics[:transfer_totals_cents].keys
      .reject { |name| StripeMethods::cosmic_fit_recipient?(name) || StripeMethods::cosmic_loft_recipient?(name) }
      .sort_by { |name| [-StripeMethods::transfer_total_for(period_metrics, name).to_i, name.to_s.downcase] }

    rows = []
    rows << ['Stripe Period Summary']
    rows << ['Category', ''] + month_labels + ['', "#{period_start} to #{period_end}"]
    rows << []
    rows << Sheets::period_summary_row('class_payments', :class_payments_cents, month_metrics, period_metrics)
    rows << Sheets::period_summary_row('point_rentals', :point_rentals_cents, month_metrics, period_metrics)
    rows << Sheets::period_summary_row('packages', :packages_cents, month_metrics, period_metrics)
    rows << Sheets::period_summary_row('event_tickets', :event_tickets_cents, month_metrics, period_metrics)
    rows << Sheets::period_summary_row('room_rentals', :room_rentals_cents, month_metrics, period_metrics)
    rows << []
    rows << Sheets::period_summary_row('paypal_income', :paypal_income_cents, month_metrics, period_metrics)
    rows << []
    rows << Sheets::period_summary_row('TOTAL INCOME', :total_income_cents, month_metrics, period_metrics)
    rows << []
    rows << Sheets::period_summary_row('refunds', :refunds_cents, month_metrics, period_metrics)
    rows << Sheets::period_summary_row('stripe_fees', :stripe_fees_cents, month_metrics, period_metrics)
    rows << Sheets::period_summary_row('paypal_expenses', :paypal_expenses_cents, month_metrics, period_metrics)
    rows << []

    other_recipients.each do |recipient|
      rows << Sheets::period_summary_row(recipient, recipient, month_metrics, period_metrics)
    end

    rows << []
    rows << Sheets::period_summary_row('PAYROLL TOTAL', :other_transfer_total_cents, month_metrics, period_metrics)
    rows << Sheets::period_summary_row('Cosmic Loft', :cosmic_loft_cents, month_metrics, period_metrics)
    rows << []
    rows << Sheets::period_summary_row('Chase Expenses', :chase_expenses_cents, month_metrics, period_metrics)
    rows << Sheets::period_summary_row('Paypal Expenses', :paypal_expenses_cents, month_metrics, period_metrics)
    rows << []
    rows << Sheets::period_summary_row('TOTAL EXPENSES', :total_expenses_cents, month_metrics, period_metrics)
    rows << []
    rows << Sheets::period_summary_row('NET', :net_cents, month_metrics, period_metrics)
    rows << Sheets::period_summary_row('Cosmic Fit Club (Transfer Out)', :transfers_out_bank_cents, month_metrics, period_metrics)

    rows
  end

  def Sheets::loft_summary_rows(month_ranges, period_start, period_end, loft_metrics_by_month, account_mask)
    month_labels = month_ranges.map { |month_start, _month_end| month_start.strftime('%b').upcase }
    income_values_cents = month_ranges.map do |month_start, _month_end|
      (loft_metrics_by_month[month_start.strftime('%Y-%m')] || {})[:income_cents].to_i
    end
    expense_values_cents = month_ranges.map do |month_start, _month_end|
      (loft_metrics_by_month[month_start.strftime('%Y-%m')] || {})[:expense_cents].to_i
    end

    total_income_cents = income_values_cents.sum
    total_expense_cents = expense_values_cents.sum
    net_cents = total_income_cents - total_expense_cents

    category_names = month_ranges.map do |month_start, _month_end|
      month_key = month_start.strftime('%Y-%m')
      metrics = loft_metrics_by_month[month_key] || {}
      (metrics[:category_totals_cents] || {}).keys
    end.flatten.uniq.sort

    rows = []
    rows << ['Loft Period Summary']
    rows << ['Account Mask', account_mask]
    rows << ['Category', ''] + month_labels + ['', "#{period_start} to #{period_end}"]
    rows << []
    rows << ['TOTAL INCOME', ''] + income_values_cents.map { |c| c.to_f / 100.0 } + ['', total_income_cents.to_f / 100.0]
    rows << ['TOTAL EXPENSES', ''] + expense_values_cents.map { |c| c.to_f / 100.0 } + ['', total_expense_cents.to_f / 100.0]
    rows << ['NET', ''] + month_ranges.each_with_index.map { |_, idx| (income_values_cents[idx] - expense_values_cents[idx]).to_f / 100.0 } + ['', net_cents.to_f / 100.0]

    unless category_names.empty?
      rows << []
      category_names.each do |category|
        category_values_cents = month_ranges.map do |month_start, _month_end|
          month_key = month_start.strftime('%Y-%m')
          metrics = loft_metrics_by_month[month_key] || {}
          (metrics[:category_totals_cents] || {})[category].to_i
        end
        rows << [category, ''] + category_values_cents.map { |c| c.to_f / 100.0 } + ['', category_values_cents.sum.to_f / 100.0]
      end
    end

    rows
  end

  def Sheets::month_slices(from_date, to_date)
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

  def Sheets::pnl_month_tab_rows(month_start, month_end)
    report = StripeMethods::monthly_pnl_report(month_start.to_s, month_end.to_s)
    Sheets::pnl_month_tab_rows_from_report(report)
  end

  def Sheets::pnl_month_tab_rows_from_report(report)
    rows = []
    rows.concat(Sheets::monthly_pnl_rows(report))
    rows << []
    rows.concat(Sheets::monthly_transaction_rows(report))
    rows
  end

  def Sheets::empty_pnl_report(from_date, to_date)
    {
      from: from_date,
      to: to_date,
      summary: {
        gross_sales_cents: 0,
        refunds_cents: 0,
        disputes_cents: 0,
        adjustments_cents: 0,
        payouts_cents: 0,
        transfers_cents: 0,
        fees_cents: 0,
        net_cents: 0
      },
      transactions: []
    }
  end

  def Sheets::safe_period_pnl_report(from_date, to_date)
    StripeMethods::monthly_pnl_report(
      from_date.to_s,
      to_date.to_s,
      include_invoice_recipients: false,
      include_transfer_recipients: true
    )
  rescue => e
    Slack.err("Stripe Period P&L Report Error (#{from_date} to #{to_date})", e)
    Sheets::empty_pnl_report(from_date, to_date)
  end

  def Sheets::create_monthly_stripe_pnl_sheet(year_or_from, month_or_to, options = {})
    account_mask = options[:account_mask].to_s.strip
    account_mask = '1067' if account_mask.empty?
    loft_only = (account_mask == '5785')

    if year_or_from.to_s =~ /^\d{4}$/ && month_or_to.to_s =~ /^\d{1,2}$/
      year = year_or_from.to_i
      month = month_or_to.to_i
      start = Date.new(year, month, 1)
      finish = start.next_month.prev_day
    else
      start = Date.parse(year_or_from.to_s)
      finish = Date.parse(month_or_to.to_s)
      start, finish = finish, start if finish < start
    end

    month_ranges = Sheets::month_slices(start, finish)
    period_report = loft_only ? Sheets::empty_pnl_report(start, finish) : Sheets::safe_period_pnl_report(start, finish)
    period_transactions = period_report[:transactions] || []
    paypal_payload = loft_only ? nil : PayPalSDK::monthly_transactions_payload(start, finish)
    chase_expenses_by_month = Sheets::chase_expenses_by_month_for_mask(account_mask, start, finish)
    loft_metrics_by_month = loft_only ? Sheets::loft_metrics_by_month_for_mask(account_mask, start, finish) : nil

    month_reports = if loft_only
      []
    else
      month_ranges.map do |month_start, month_end|
        monthly_transactions = period_transactions.select do |row|
          created = row[:created]
          next false if created.nil?
          day = created.to_date
          day >= month_start && day <= month_end
        end
        StripeMethods::report_from_transactions(monthly_transactions, month_start, month_end)
      end
    end
    sheets, drive = Sheets::get_service2

    title = if month_ranges.length > 1
      suffix = loft_only ? 'Loft P&L' : 'Stripe P&L'
      "#{start.strftime('%Y-%m-%d')} to #{finish.strftime('%Y-%m-%d')} #{suffix}"
    else
      suffix = loft_only ? 'Loft P&L' : 'Stripe P&L'
      "#{start.strftime('%Y-%m')} #{suffix}"
    end

    file = Sheets::create_sheet(drive, title, "1RvnAXjk20LdCrv6AunMWfhzLb81T-_9n")

    Sheets::rename_sheet(sheets, file.id, 0, "Summary")
    if loft_only
      Sheets::fill_sheet(sheets, file.id, "Summary", Sheets::loft_summary_rows(month_ranges, start, finish, loft_metrics_by_month || {}, account_mask))
    else
      Sheets::fill_sheet(sheets, file.id, "Summary", Sheets::period_summary_rows(month_ranges, month_reports, start, finish, paypal_payload, chase_expenses_by_month))
    end

    unless loft_only
      month_ranges.each_with_index do |(month_start, _month_end), index|
        tab_name = month_start.strftime('%b %Y')
        report = month_reports[index]
        if index == 0
          Sheets::add_sheet(sheets, file.id, tab_name)
        else
          Sheets::add_sheet(sheets, file.id, tab_name)
        end
        Sheets::fill_sheet(sheets, file.id, tab_name, Sheets::pnl_month_tab_rows_from_report(report))
      end
    end

    unless loft_only
      begin
        Sheets::add_sheet(sheets, file.id, 'PayPal Transactions')
        Sheets::fill_sheet(sheets, file.id, 'PayPal Transactions', PayPalSDK::transactions_sheet_rows(start, finish, paypal_payload))
      rescue => e
        Slack.err('PayPal Sheet Tab Error', e)
        begin
          Sheets::add_sheet(sheets, file.id, 'PayPal')
          Sheets::fill_sheet(sheets, file.id, 'PayPal', PayPalSDK::transactions_sheet_rows(start, finish, paypal_payload))
        rescue => e2
          Slack.err('PayPal Sheet Fallback Tab Error', e2)
        end
      end
    end

    begin
      chase_rows = PlaidIntegration.transactions_sheet_rows_for_mask(account_mask, start, finish)
      unless chase_rows.empty?
        tab_name = "Chase #{account_mask} Transactions"
        Sheets::add_sheet(sheets, file.id, tab_name)
        Sheets::fill_sheet(sheets, file.id, tab_name, chase_rows)
      end
    rescue => e
      Slack.err("Chase #{account_mask} Sheet Tab Error", e)
    end

    file.web_view_link || file.webViewLink
  end

  module PNL
    def self.job_dir
      dir = File.join(Dir.tmpdir, 'cosmicfit_pnl_jobs')
      FileUtils.mkdir_p(dir)
      dir
    end

    def self.job_path(job_id)
      File.join(job_dir, "#{job_id}.json")
    end

    def self.write_job(job_hash)
      path = job_path(job_hash[:job_id])
      tmp_path = "#{path}.tmp"
      File.write(tmp_path, job_hash.to_json)
      File.rename(tmp_path, path)
    end

    def self.read_job(job_id)
      path = job_path(job_id)
      return nil unless File.exist?(path)
      JSON.parse(File.read(path), symbolize_names: true)
    rescue
      nil
    end

    def self.start_job(year_or_from, month_or_to, account_mask='1067')
      job_id = SecureRandom.uuid
      now = Time.now.utc.iso8601
      self.write_job({
        status: 'queued',
        job_id: job_id,
        account_mask: account_mask,
        created_at: now,
        updated_at: now,
        url: nil,
        error: nil
      })

      pid = fork do
        begin
          self.update_job(job_id, status: 'running', updated_at: Time.now.utc.iso8601)
          url = Sheets::create_monthly_stripe_pnl_sheet(year_or_from, month_or_to, account_mask: account_mask)
          self.update_job(job_id, status: 'completed', url: url, updated_at: Time.now.utc.iso8601)
        rescue => e
          Slack.err('Stripe P&L Background Job Error', e)
          self.update_job(
            job_id,
            status: 'failed',
            error: "#{e.class}: #{e.message}",
            updated_at: Time.now.utc.iso8601
          )
        ensure
          exit! 0
        end
      end
      Process.detach(pid)

      { job_id: job_id, status: 'queued' }
    end

    def self.job_status(job_id)
      return nil if job_id.nil? || job_id.to_s.strip.empty?

      self.read_job(job_id.to_s)
    end

    def self.update_job(job_id, attrs)
      current = self.read_job(job_id)
      return unless current
      self.write_job(current.merge(attrs))
    end
  end

end
