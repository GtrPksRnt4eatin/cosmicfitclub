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
    sheets = Sheets::get_service or return
    spreadsheet_id = '1XckfZT_IRPZ43VCadw8yiQzUN4Xv5eh8IWbFI01ZLKE'
    range = 'A2:B30'
    response = sheets.get_spreadsheet_values(spreadsheet_id, range)
    response.values.map! { |val| { :question => val[0], :answer => val[1] } }
    response.values
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

#    folder = svc.file_by_id("1gEYA96NDJcToN_bJQ0_OpluI-ISYHyVg")
#    sheet = folder.file_by_title(title)
#    sheet ||= folder.create_spreadsheet(title)
#
#    wksht = sheet.worksheets[0]
#    wksht.update_cells(1,1,evt.accounting_arr)
#    wksht.title = "Accounting"
#    wksht.save
#
#    wksht2 = sheet.add_worksheet("Attendance") if sheet.worksheets.count == 1 
#    wksht2 = sheet.worksheets[1]           unless sheet.worksheets.count == 1 
#    wksht2.update_cells(1,1,evt.attendance_arr)
#    wksht2.save
#
#    return sheet.human_url
#  end
  
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

  #  folder = svc.folder_by_id("1xFj5h7TuijiksYvmvu2rqjgtOqaHnyeJ")
  #  sheet = folder.file_by_name(title)
  #  sheet ||= folder.create_spreadsheet(title)
    
  #  wksht = sheet.worksheets[0]
  #  wksht.update_cells(1,1,Staff::payroll_csv(from,to).to_a)
  #  wksht.title = "Payroll"
  #  wksht.save
    
  #  return sheet.human_url
  #end
  
  def Sheets::create_PNL_sheet(start_date, end_date)
    title = "PNL #{start_date} to #{end_date}"
    sheets, drive = Sheets::get_service2
    folder_id = "1RvnAXjk20LdCrv6AunMWfhzLb81T-_9n"

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
          update_sheet_properties: { properties: { sheet_id: 0, title: title },
            fields: "title"
          },
        }
      ]
    )
    sheets.batch_update_spreadsheet(sheet_id, batch_req)

    arr = StripeMethods::get_transactions(start_date, end_date)
    puts "DEBUG: Transactions array has #{arr.length} rows"
    puts "DEBUG: First row: #{arr.first.inspect}"
    values = Google::Apis::SheetsV4::ValueRange.new(values: arr)
    begin
      # Use the sheet title that was set in batch_update_spreadsheet
      range = "#{title}!A1"
      puts "DEBUG: Writing to range: #{range}"
      sheets.update_spreadsheet_value(sheet_id, range, values, value_input_option: 'USER_ENTERED')
    rescue => e
      puts "ERROR updating spreadsheet: #{e.class}: #{e.message}"
      puts e.backtrace.first(5).join("\n")
      raise
    end
    return file.web_view_link || file.webViewLink
  end
end
