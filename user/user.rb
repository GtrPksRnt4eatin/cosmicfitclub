require 'sinatra/base'

class CFCuser < Sinatra::Base

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  register Sinatra::Auth

  set :root, File.dirname(__FILE__)

  get( '/',               :auth => 'user'      ) { ref_cust; render_page :user           }
  get( '/wallet_history', :auth => 'user'      ) { ref_cust; render_page :wallet_history }
  get( '/teacher',        :auth => 'teacher'   ) { ref_cust; render_page :teacher        }
  get( '/hourly',         :auth => 'frontdesk' ) { render_page :hourly                   }
  get( '/event_collab',   :auth => 'user'      ) { render_page :event_collab             

  get '/session' do
    content_type :json 
    session.to_json
  end

  error do
    Slack.err( 'User Page Error', env['sinatra.error'] )
    'An Error Occurred.'
  end

end