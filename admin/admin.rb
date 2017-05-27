require 'sinatra/base'
require 'autoforme'
require 'forme/bs3'

class CFCAdmin < Sinatra::Base

  enable :sessions	
  set :root, File.dirname(__FILE__)

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  register Sinatra::Auth
  
  get( '/',           :auth=> 'admin' ) { render_page :index            }
  get( '/carousel',   :auth=> 'admin' ) { render_page :carousel         }
  get( '/classes',    :auth=> 'admin' ) { render_page :classes          }
  get( '/events',     :auth=> 'admin' ) { render_page :events           }
  get( '/staff',      :auth=> 'admin' ) { render_page :staff            }
  get( '/events/:id' )                  { render_page :event_edit       }
  get( '/events/:id/checkin' )          { render_page :event_checkin    }
  get( '/events/:id/accounting')        { render_page :event_accounting }
  get( '/classes/:id')                  { render_page :class_edit       }
  get( '/door',       :auth=> 'door'  ) { render_page :door             }
  get( '/balance',                    ) { render_page :balance_sheet    }
  get( '/class_checkin'               ) { render_page :class_checkin    }

end

class Autoforme < Sinatra::Base
  
  AutoForme.for(:sinatra, self) do

    order [:name]

    model Event
    model EventSession
    model EventPrice

    association_links :all

  end

end