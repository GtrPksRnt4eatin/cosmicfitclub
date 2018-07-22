require 'sinatra/base'

class CFC < Sinatra::Base

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  register Sinatra::Auth

  set :root, File.dirname(__FILE__)

  get( '/' )                 { render_page :index    } 
  get( '/classes')           { render_page :classes  }
  get( '/training')          { render_page :training }
  get( '/events')            { render_page :events   }
  get( '/schedule')          { render_page :schedule }
  get( '/staff')             { render_page :staff    }
  get( '/pricing')           { render_page :pricing  }
  get( '/faq')               { render_page :faq      }
  get( '/kids')              { render_page :kids     }
  get( '/media')             { render_page :media    }

  get( '/schedule_week')     { render_page :schedule_week }

  get( '/waiver', :auth => 'user' ) { render_page :waiver }

  get( '/badass' ) { redirect '/checkout/event/257' }

  get( '/checkout')               { render_page :checkout }
  get( '/checkout/plans/:id' )    { render_page :checkout_plan }
  get( '/checkout/packages/:id' ) { render_page :checkout_pack }
  get( '/checkout/complete')      { render_page :checkout_complete }

  get( '/login' ) { redirect('/auth/login') }

  post( '/waiver', :auth => 'user' ) do
    session[:customer].waiver = Waiver.create(:signature => request.body.read )
    return 204
  end

  get( '/robots.txt') do
    "User-agent: * \r\nDisallow:"
  end
  
end