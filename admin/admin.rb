require 'sinatra/base'

class CFCAdmin < Sinatra::Base

  enable :sessions	
  set :root, File.dirname(__FILE__)

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources

  get( '/'         ) { render_page :index    }
  get( '/carousel' ) { render_page :carousel }
  get( '/classes'  ) { render_page :classes  }
  get( '/events'   ) { render_page :events   }
  get( '/staff'    ) { render_page :staff    }

end