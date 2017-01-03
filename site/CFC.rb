require 'sinatra/base'

class CFC < Sinatra::Base

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources

  set :root, File.dirname(__FILE__)

  get( '/' )        { render_page :index    } 
  get( '/classes')  { render_page :classes  }
  get( '/training') { render_page :training }
  get( '/events')   { render_page :events   }
  get( '/schedule') { render_page :schedule }
  get( '/staff')    { render_page :staff    }
  get( '/pricing')  { render_page :pricing  }
  get( '/faq')      { render_page :faq      }
  get( '/store')    { render_page :store    }
  get( '/checkout') { render_page :checkout }

  get( '/checkout/plans/:id' )    { render_page :checkout_plans }
  get( '/checkout/packages/:id' ) { render_page :checkout_pack  }

end