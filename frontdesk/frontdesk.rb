require 'sinatra/base'
require 'rest-client'

class CFCFrontDesk < Sinatra::Base

  set :root, File.dirname(__FILE__)

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  register Sinatra::Auth

  configure do
    set :start_time, Time.now
  end

  before do
    last_modified settings.start_time
    etag settings.start_time.to_s
    cache_control :no_cache
  end

  get( '/class_checkin',        :auth => "frontdesk" ) { render_page :class_checkin    }
  get( '/class_attendance/:id', :auth => "frontdesk" ) { render_page :class_attendance }
  get( '/event_checkin',        :auth => "frontdesk" ) { render_page :event_checkin    }
  get( '/event_attendance/:id', :auth => "frontdesk" ) { render_page :event_attendance }
  get( '/customer_file',        :auth => "frontdesk" ) { render_page :customer_file    }
  get( '/dashboard',            :auth => "frontdesk" ) { render_page :dashboard        }

  get '/bus_times' do
    stop_id_north = 'MTA_307214'
    stop_id_south = 'MTA_302278'
    resp_north = RestClient.get( "https://bustime.mta.info/api/siri/stop-monitoring.json?MonitoringRef=#{stop_id_north}&key=#{ENV['BUSTIME_KEY']}", :content_type=>'application/json', :timeout=>1)
    resp_south = RestClient.get( "https://bustime.mta.info/api/siri/stop-monitoring.json?MonitoringRef=#{stop_id_south}&key=#{ENV['BUSTIME_KEY']}", :content_type=>'application/json', :timeout=>1)
    { :north => unpack_bus_times(resp_north),
      :south => unpack_bus_times(resp_south)
    }.to_json
  end

  def unpack_bus_times(resp)
    resp = JSON.parse(resp)["Siri"]["ServiceDelivery"]["StopMonitoringDelivery"][0]["MonitoredStopVisit"]
    resp.map! { |x| x["MonitoredVehicleJourney"]["MonitoredCall"] } unless resp.nil?
    resp.map! { |y| { 
      :arrival=> Time.parse(y["ExpectedArrivalTime"]).strftime("%I:%M %P"), 
      :arrives_in=> (Time.parse(y["ExpectedArrivalTime"])-Time.now).to_i/60, 
      :stops=> y["Extensions"]["Distances"]["StopsFromCall"]
    } } unless resp.nil?
    resp
  end
  
  not_found do
    'This is nowhere to be found.'
  end

  error do
    Slack.err( 'Front Desk Error', env['sinatra.error'] )
    'An Error Occurred.'
  end

end
