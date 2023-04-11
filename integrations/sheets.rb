require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'
require 'stringio'
require 'google_drive'

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
    GoogleDrive::Session.from_service_account_key(io)
  end

  def Sheets::create_event_sheet(event_id)
    evt = Event[event_id] or return false
    title = evt.starttime.strftime("%Y-%m-%d [\##{evt.id}] #{evt.name}")
    svc = Sheets::get_service2
    folder = svc.folder_by_id("1gEYA96NDJcToN_bJQ0_OpluI-ISYHyVg")
    sheet = folder.file_by_name(title)
    sheet ||= folder.create_spreadsheet(title)

    wksht = sheet.worksheets[0]
    wksht.update_cells(1,1,evt.accounting_arr)
    wksht.title = "Accounting"
    wksht.save

    wksht2 = sheet.add_worksheet("Attendance") if sheet.worksheets.count == 1 
    wksht2 = sheet.worksheets[1]           unless sheet.worksheets.count == 1 
    wksht2.update_cells(1,1,evt.attendance_arr)
    wksht2.save

    return sheet.human_url
  end
  
  def Sheets::create_payroll_sheet(from,to)
    title = "#{from} to #{to}"
    svc = Sheets::get_service2
    folder = svc.folder_by_id("1xFj5h7TuijiksYvmvu2rqjgtOqaHnyeJ")
    sheet = folder.file_by_name(title)
    sheet ||= folder.create_spreadsheet(title)
    
    wksht = sheet.worksheets[0]
    wksht.update_cells(1,1,Staff::payroll_csv(from,to).to_a)
    wksht.title = "Payroll"
    wksht.save
    
    return sheet.human_url
  end

end
