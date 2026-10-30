require 'google/apis/sheets_v4'
require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'
require 'stringio'

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
      Sheets::transfer_recipient_from_description(row[:description])
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

  def Sheets::transfer_recipient_from_description(description)
    text = description.to_s.strip
    parts = text.split(/\bto\b/i).map { |part| part.to_s.strip }.reject(&:empty?)
    recipient = parts.length > 1 ? parts.last : text
    recipient.empty? ? 'Unknown' : recipient
  end

  def Sheets::transfer_totals_by_recipient(report)
    totals = Hash.new(0)
    report[:transactions].each do |row|
      next unless row[:section] == 'Transfers'
      recipient = Sheets::transfer_recipient_from_description(row[:description])
      totals[recipient] += row[:amount_cents].to_i.abs
    end
    totals
  end

  def Sheets::period_metrics(report)
    by_section = report[:transactions].group_by { |row| row[:section] }
    sum_section = lambda { |name| (by_section[name] || []).sum { |row| row[:amount_cents].to_i } }

    {
      class_payments_cents: sum_section.call('Class Purchases'),
      point_rentals_cents: sum_section.call('Point Rentals'),
      packages_cents: sum_section.call('Packages'),
      event_tickets_cents: sum_section.call('Event Tickets'),
      room_rentals_cents: sum_section.call('Invoices'),
      refunds_cents: report[:summary][:refunds_cents].to_i.abs,
      stripe_fees_cents: report[:summary][:fees_cents].to_i.abs,
      transfer_totals_cents: Sheets::transfer_totals_by_recipient(report)
    }
  end

  def Sheets::transfer_total_for(metrics, label)
    key = metrics[:transfer_totals_cents].keys.find { |name| name.to_s.downcase == label.to_s.downcase }
    key ? metrics[:transfer_totals_cents][key].to_i : 0
  end

  def Sheets::metrics_value(metrics, key)
    cosmic_fit = Sheets::transfer_total_for(metrics, 'Cosmic Fit Club')
    cosmic_loft = Sheets::transfer_total_for(metrics, 'Cosmic Loft')
    others = metrics[:transfer_totals_cents]
      .reject { |name, _| ['cosmic fit club', 'cosmic loft'].include?(name.to_s.downcase) }
      .values
      .sum

    income_total =
      metrics[:class_payments_cents].to_i +
      metrics[:point_rentals_cents].to_i +
      metrics[:packages_cents].to_i +
      metrics[:event_tickets_cents].to_i +
      metrics[:room_rentals_cents].to_i

    expenses_total =
      metrics[:refunds_cents].to_i +
      metrics[:stripe_fees_cents].to_i +
      cosmic_fit + cosmic_loft + others

    if key.is_a?(String)
      return Sheets::transfer_total_for(metrics, key)
    end

    case key
    when :class_payments_cents then metrics[:class_payments_cents].to_i
    when :point_rentals_cents then metrics[:point_rentals_cents].to_i
    when :packages_cents then metrics[:packages_cents].to_i
    when :event_tickets_cents then metrics[:event_tickets_cents].to_i
    when :room_rentals_cents then metrics[:room_rentals_cents].to_i
    when :paypal_income_cents then nil
    when :total_income_cents then income_total
    when :income_less_room_cents then income_total - metrics[:room_rentals_cents].to_i
    when :refunds_cents then metrics[:refunds_cents].to_i
    when :stripe_fees_cents then metrics[:stripe_fees_cents].to_i
    when :cosmic_fit_club_cents then cosmic_fit
    when :cosmic_loft_cents then cosmic_loft
    when :other_transfer_total_cents then others
    when :chase_expenses_cents then nil
    when :paypal_expenses_cents then nil
    when :total_expenses_cents then expenses_total
    when :net_cents then income_total - expenses_total
    when :net_less_loft_cents then (income_total - expenses_total) - cosmic_loft
    else
      nil
    end
  end

  def Sheets::period_summary_row(label, key, month_metrics, period_metrics)
    values = month_metrics.map do |metrics|
      cents = Sheets::metrics_value(metrics, key)
      cents.nil? ? nil : (cents.to_f / 100.0)
    end

    total_cents = Sheets::metrics_value(period_metrics, key)
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
      totals[:refunds_cents] += metrics[:refunds_cents].to_i
      totals[:stripe_fees_cents] += metrics[:stripe_fees_cents].to_i
      metrics[:transfer_totals_cents].each do |recipient, amount|
        totals[:transfer_totals_cents][recipient] += amount.to_i
      end
    end

    totals
  end

  def Sheets::period_summary_rows(month_ranges, month_reports, period_start, period_end)
    month_labels = month_ranges.map { |month_start, _month_end| month_start.strftime('%b').upcase }
    month_metrics = month_reports.map { |report| Sheets::period_metrics(report) }
    period_metrics = Sheets::aggregate_period_metrics(month_metrics)

    other_recipients = period_metrics[:transfer_totals_cents].keys
      .reject { |name| ['cosmic fit club', 'cosmic loft'].include?(name.to_s.downcase) }
      .sort

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
    rows << Sheets::period_summary_row('INCOME LESS ROOM RENTALS', :income_less_room_cents, month_metrics, period_metrics)
    rows << []
    rows << Sheets::period_summary_row('refunds', :refunds_cents, month_metrics, period_metrics)
    rows << Sheets::period_summary_row('stripe_fees', :stripe_fees_cents, month_metrics, period_metrics)
    rows << Sheets::period_summary_row('Cosmic Fit Club', :cosmic_fit_club_cents, month_metrics, period_metrics)
    rows << Sheets::period_summary_row('Cosmic Loft', :cosmic_loft_cents, month_metrics, period_metrics)

    other_recipients.each do |recipient|
      rows << Sheets::period_summary_row(recipient, recipient, month_metrics, period_metrics)
    end

    rows << []
    rows << Sheets::period_summary_row('PAYROLL TOTAL', :other_transfer_total_cents, month_metrics, period_metrics)
    rows << []
    rows << Sheets::period_summary_row('Chase Expenses', :chase_expenses_cents, month_metrics, period_metrics)
    rows << Sheets::period_summary_row('Paypal Expenses', :paypal_expenses_cents, month_metrics, period_metrics)
    rows << []
    rows << Sheets::period_summary_row('TOTAL EXPENSES', :total_expenses_cents, month_metrics, period_metrics)
    rows << []
    rows << Sheets::period_summary_row('NET', :net_cents, month_metrics, period_metrics)
    rows << Sheets::period_summary_row('NET LESS LOFT', :net_less_loft_cents, month_metrics, period_metrics)

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

  def Sheets::create_monthly_stripe_pnl_sheet(year_or_from, month_or_to)
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
    month_reports = month_ranges.map do |month_start, month_end|
      StripeMethods::monthly_pnl_report(month_start.to_s, month_end.to_s)
    end
    sheets, drive = Sheets::get_service2

    title = if month_ranges.length > 1
      "#{start.strftime('%Y-%m-%d')} to #{finish.strftime('%Y-%m-%d')} Stripe P&L"
    else
      "#{start.strftime('%Y-%m')} Stripe P&L"
    end

    file = Sheets::create_sheet(drive, title, "1RvnAXjk20LdCrv6AunMWfhzLb81T-_9n")

    Sheets::rename_sheet(sheets, file.id, 0, "Summary")
    Sheets::fill_sheet(sheets, file.id, "Summary", Sheets::period_summary_rows(month_ranges, month_reports, start, finish))

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

    file.web_view_link || file.webViewLink
  end

end
