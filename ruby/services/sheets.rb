require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

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
    service.create_spreadsheet(request_body)
  end

  def Sheets::get_service
    sheets = Google::Apis::SheetsV4::SheetsService.new
    sheets.client_options.application_name = APPLICATION_NAME
    sheets.authorization = Sheets.authorize
    sheets.authorization.nil? ? nil : sheets
  end

end