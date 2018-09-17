require 'sinatra/base'

class CFCFrontDesk < Sinatra::Base

  set :root, File.dirname(__FILE__)

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  register Sinatra::Auth

  before do
    cache_control :no_cache
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
    Slack.post("#{env['sinatra.error'].message}\r\r```#{env['sinatra.error'].backtrace.join("\r")}```" )
    'An Error Occurred.'
  end

end