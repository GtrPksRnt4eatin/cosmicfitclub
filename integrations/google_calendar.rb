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

    def Calendar::get_loft_events
      service = self::get_service
      events = service.list_events('sam@cosmicfitclub.com', single_events: true, order_by: 'startTime', time_min: Time.now.iso8601).items
      events.map do |x| 
        { :start => x.start.date || x.start.date_time,
          :end => x.end.date || x.end.date_time,
          :summary => x.summary,
          :allday => x.start.date_time ? false : true
        }
      end
    end

end