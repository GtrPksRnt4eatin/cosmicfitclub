require 'sinatra/base'

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
    cache_control :public, max_age: 604800
  end

  get( '/class_checkin',        :auth => "frontdesk" ) { render_page :class_checkin    }
  get( '/class_attendance/:id', :auth => "frontdesk" ) { render_page :class_attendance }
  get( '/event_checkin',        :auth => "frontdesk" ) { render_page :event_checkin    }
  get( '/event_attendance/:id', :auth => "frontdesk" ) { render_page :event_attendance }
  get( '/customer_file',        :auth => "frontdesk" ) { render_page :customer_file    }
  
  not_found do
    'This is nowhere to be found.'
  end

  error do
    Slack.err( 'Front Desk Error', env['sinatra.error'] )
    'An Error Occurred.'
  end

end