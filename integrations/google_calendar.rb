require 'google/apis/calendar_v3'
require 'googleauth'

module Calendar

    def Calendar::get_service
      scope = 'https://www.googleapis.com/auth/calendar'
      authorizer = Google::Auth::ServiceAccountCredentials.make_creds( 
        json_key_io: StringIO.new(ENV['GOOGLE_SERVICE']),
        scope: scope
      )
      authorizer.fetch_access_token!

      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = authorizer
      service
    end
  

end