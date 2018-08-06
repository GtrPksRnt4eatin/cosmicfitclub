require 'sinatra/base'

class CFCFrontDesk < Sinatra::Base

  set :root, File.dirname(__FILE__)

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  register Sinatra::Auth

  get( '/class_checkin',    :auth => "frontdesk" ) { render_page :class_checkin    }
  get( '/class_attendance', :auth => "frontdesk" ) { render_page :class_attendance }
  get( '/event_checkin',    :auth => "frontdesk" ) { render_page :event_checkin    }
  get( '/customer_file',    :auth => "frontdesk" ) { render_page :customer_file    }
  
end