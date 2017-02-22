require 'sinatra/base'

class CFCAdmin < Sinatra::Base

  enable :sessions	
  set :root, File.dirname(__FILE__)

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  register Sinatra::Auth
  
  get( '/',           :auth=> 'admin' ) { render_page :index      }
  get( '/carousel',   :auth=> 'admin' ) { render_page :carousel   }
  get( '/classes',    :auth=> 'admin' ) { render_page :classes    }
  get( '/events',     :auth=> 'admin' ) { render_page :events     }
  get( '/staff',      :auth=> 'admin' ) { render_page :staff      }
  get( '/events/:id' ) { render_page :event_edit }

end