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

  #get( '/kids')              { render_page :kids     }

  ####################### TEST PAGES #########################
  
  get( '/waiver', :auth => 'user' ) { render_page :waiver }

  get( '/checkout')                 { render_page :checkout }
  get( '/checkout/plans/:id' )      { render_page :checkout_plan }
  get( '/checkout/packages/:id' )   { render_page :checkout_pack }
  get( '/checkout/complete')        { render_page :checkout_complete }

  get( '/covid19' )                 { render_page :covid19           }

  get( '/login' ) { redirect('/auth/login') }

  post( '/waiver', :auth => 'user' ) do
    Customer[session[:customer_id]].add_waiver( Waiver.create(:signature => request.body.read ) )
    return 204
  end

  get( '/robots.txt') { "User-agent: * \r\nDisallow:" }

  get( '/:tag' ) do
    url = ShortUrl.where(:short_path => params[:tag]).first or pass
    redirect url.long_path
  end

  error do
    Slack.err( 'Site Error', env['sinatra.error'] )
    'An Error Occurred.'
  end
  
end
