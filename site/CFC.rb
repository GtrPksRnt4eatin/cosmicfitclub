require 'sinatra/base'

class CFC < Sinatra::Base

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  register Sinatra::Auth

  set :root, File.dirname(__FILE__)

  configure do
    set :start_time, Time.now
  end

  #before do
  #  last_modified settings.start_time
  #  etag settings.start_time.to_s
  #  cache_control :public, max_age: 604800
  #end

  get( '/' )                 { render_page :index    } 
  get( '/events')            { render_page :events   }
  get( '/classes')           { render_page :classes  }
  get( '/schedule')          { render_page :schedule }
  get( '/training')          { render_page :training }
  get( '/pricing')           { render_page :pricing  }
  get( '/staff')             { render_page :staff    }
  get( '/media')             { render_page :media    }
  get( '/faq')               { render_page :faq      }  


  ####################### TEST PAGES #########################

  get( '/kids')              { render_page :kids     }
  get( '/class/:id')         { render_page :class    }

  ####################### TEST PAGES #########################
  

  get( '/waiver', :auth => 'user' ) { render_page :waiver }
  
  get( '/nicolasinny' )             { redirect '/checkout/event/368' }
  get( '/NicolasInNY')              { redirect '/checkout/event/368' }
  get( '/meditation' )              { redirect '/checkout/event/362' }
  get( '/insideflow' )              { redirect '/checkout/event/363' }

  get( '/checkout')                 { render_page :checkout }
  get( '/checkout/plans/:id' )      { render_page :checkout_plan }
  get( '/checkout/packages/:id' )   { render_page :checkout_pack }
  get( '/checkout/complete')        { render_page :checkout_complete }

  get( '/login' ) { redirect('/auth/login') }

  post( '/waiver', :auth => 'user' ) do
    session[:customer].add_waiver( Waiver.create(:signature => request.body.read ) )
    return 204
  end

  get( '/robots.txt') { "User-agent: * \r\nDisallow:" }

  error do
    Slack.err( 'Site Error', env['sinatra.error'] )
    'An Error Occurred.'
  end
  
end