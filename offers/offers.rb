require 'sinatra/base'

class CFCOffers < Sinatra::Base

  set :root, File.dirname(__FILE__)

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  register Sinatra::Auth

  before do
    cache_control :no_store
  end

  get( '/newstudent'  )  { render_page :new_student  }
  get( '/redeem_gift' )  { render_page :gift_cert    }
  get( '/survey'      )  { render_page :survey       }
  get( '/giftcard'    )  { render_page :holiday_sale }

  not_found do
    @err="Sorry, This Offer Is No Longer Available."
    render_page :error
  end

  error do
    Slack.err( 'Offers Error', env['sinatra.error'] )
    'An Error Occurred.'
  end

end
