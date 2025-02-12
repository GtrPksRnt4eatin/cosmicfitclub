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
        { :gcal_id  => x.id,
          :start    => x.start.date || x.start.date_time,
          :end      => x.end.date || x.end.date_time,
          :summary  => x.summary,
          :location => x.location,
          :allday   => x.start.date_time ? false : true
        }
      end.reject { |x| x[:allday] || !x[:location] }
    end

    def Calendar::get_loft_events(from,to)
      service = self::get_service
      events = service.list_events('sam@cosmicfitclub.com', single_events: true, order_by: 'startTime', time_min: from.iso8601, time_max: to.iso8601).items
      events.map do |x| 
        { :gcal_id  => x.id,
          :start    => x.start.date || x.start.date_time,
          :end      => x.end.date || x.end.date_time,
          :summary  => x.summary,
          :location => x.location,
          :allday   => x.start.date_time ? false : true,
          :source   => "google_calendar"
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

    def Calendar::delete_event(event_id)
      svc = self::get_service
      svc.delete_event('sam@cosmicfitclub.com', event_id) rescue nil
    end

    def Calendar::update_event(event_id)
      svc = self::get_service
      evt = svc.get_event('sam@cosmicfitclub.com', event_id)
      yield evt
      svc.update_event('sam@cosmicfitclub.com', event_id, evt).updated
    end

    def Calendar::subscribe_to_changes
      @@channel_id = Time.now.to_i
      channel = Google::Apis::CalendarV3::Channel.new(address: 'https://cosmicfitclub.com/models/groups/gcal_updates', id: @@channel_id, type: "web_hook")
      webhook = self.get_service.watch_event('sam@cosmicfitclub.com', channel, single_events: true, time_min: Time.now.iso8601)
    end

    def Calendar::fetch_changes(update)
      svc = self.get_service     
      if(update["HTTP_X_GOOG_CHANNEL_ID"].to_i != @@channel_id)
        svc.stop_channel(Google::Apis::CalendarV3::Channel.new(id: update["HTTP_X_GOOG_CHANNEL_ID"].to_i, resource_id: update["HTTP_X_GOOG_RESOURCE_ID"])) rescue nil
        return nil
      end
      expiration = DateTime.parse(update["HTTP_X_GOOG_CHANNEL_EXPIRATION"])
      return nil                     if update["HTTP_X_GOOG_RESOURCE_STATE"]=="sync"
      Calendar::subscribe_to_changes if (expiration.mjd - DateTime.now.mjd < 2)
      @@last_update ||= Time.now
      result = svc.list_events('sam@cosmicfitclub.com', single_events: true, updated_min: @@last_update.iso8601).items
      @@last_update = Time.now
      result.map do |x| 
        { :id=>x.id,
          :summary=>x.summary,
          :status=>x.status,
          :start=>x.try(:start).try(:date_time),
          :end=>x.try(:end).try(:date_time)
        } 
      end
    end

end