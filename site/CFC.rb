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

  before do
    last_modified settings.start_time
    etag settings.start_time.to_s
    cache_control :no_cache
  end

  get( '/' )                 { render_page :index    } 
  get( '/events')            { render_page :events   }
  get( '/classes')           { render_page :classes  }
  get( '/schedule')          { render_page :schedule }
  get( '/training')          { render_page :training }
  get( '/pricing')           { render_page :pricing  }
  get( '/staff')             { render_page :staff    }
  get( '/media')             { render_page :media    }
  get( '/faq')               { render_page :faq      }

  get( '/class/:id')         { render_page :class    }  


  ####################### TEST PAGES #########################

  get( '/kids')              { render_page :kids     }

  ####################### TEST PAGES #########################
  

  get( '/waiver', :auth => 'user' ) { render_page :waiver }
  
  get( '/mindopen' )                { redirect '/checkout/event/383' }
  get( '/lux')                      { redirect '/checkout/event/380' }
  get( '/parkjam')                  { redirect '/checkout/event/376' }
  get( '/muscleups')                { redirect '/checkout/event/378' }
  get( '/insideflow' )              { redirect '/checkout/event/374' }
  get( '/candlelight')              { redirect '/checkout/event/371' }
  get( '/waterfrontyoga')           { redirect '/auth/onboard?page=/class/62' }

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