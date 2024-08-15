require 'google/apis/calendar_v3'
require 'googleauth'

module Calendar

    def Calendar::get_service
      scope = 'https://www.googleapis.com/auth/calendar'
      authorizer = Google::Auth::ServiceAccountCredentials.make_creds( 
        json_key_io: StringIO.new(ENV['GOOGLE_SERVICE']),
        scope: scope
      )
      authorizer.sub = "sam@cosmicfitclub.com"
      #authorizer.fetch_access_token!

      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = authorizer
      service
    end

    def Calendar::get_day_events(date)
      service = self::get_service
      start = Time.parse(date).iso8601
      finish = (Time.parse(date) + 86400).iso8601
      events = service.list_events('sam@cosmicfitclub.com', single_events: true, order_by: 'startTime', time_min: start, time_max: finish).items    
      events.map do |x| 
        { :start    => x.start.date || x.start.date_time,
          :end      => x.end.date || x.end.date_time,
          :summary  => x.summary,
          :location => x.location,
          :allday   => x.start.date_time ? false : true
        }
      end.reject { |x| x[:allday] || !x[:location] }
    end

    def Calendar::get_loft_events
      service = self::get_service
      events = service.list_events('sam@cosmicfitclub.com', single_events: true, order_by: 'startTime', time_min:  DateTime.now.prev_month(1).to_time.iso8601).items
      events.map do |x| 
        { :start    => x.start.date || x.start.date_time,
          :end      => x.end.date || x.end.date_time,
          :summary  => x.summary,
          :location => x.location,
          :allday   => x.start.date_time ? false : true
        }
      end
    end

    def Calendar::create_point_rental(start,finish,title)
      service = self::get_service
      event = Google::Apis::CalendarV3::Event.new( 
        summary: title,
        #location: "Loft-1F-Front (4)",
        start: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: start.iso8601, 
          time_zone: 'America/New_York'
        ),
        end: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: finish.iso8601,
          time_zone: 'America/New_York'
        ),
        attendees: [
          { email: "c_1886mhe5itnkig8ekabujeden03cm@resource.calendar.google.com" }
        ]
      )
      service.insert_event('sam@cosmicfitclub.com', event).id
    end

    def Calendar::update_event(event_id)
      service = self::get_service
      event = service.get_event('sam@cosmicfitclub.com',event_id)
      Slack.raw_err("event=#{event_id}",event.class)
      yield event
      Slack.raw_err("event=#{event_id}",event.to_json)
      result = service.update_event('sam@comicfitclub.com', event_id, event)
      result.updated
    end
    
end
