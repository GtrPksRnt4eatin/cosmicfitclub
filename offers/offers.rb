require 'sinatra/base'

class CFCOffers < Sinatra::Base

  set :root, File.dirname(__FILE__)

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  register Sinatra::Auth

  get( '/waterfront_deal')  { render_page :waterfront_deal }
  get( '/summersale' )      { render_page :summer_sale     }
  get( '/newstudent'  )     { render_page :new_student     }

  not_found do
    'This is nowhere to be found.'
  end

  error do
    Slack.err( 'Offers Error', env['sinatra.error'] )
    'An Error Occurred.'
  end

end
