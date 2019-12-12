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

  get( '/holiday_sale')  { render_page :holiday_sale }
  get( '/newstudent'  )  { render_page :new_student  }

  not_found do
    @err="Sorry, This Offer Is No Longer Available."
    render_page :error
  end

  error do
    Slack.err( 'Offers Error', env['sinatra.error'] )
    'An Error Occurred.'
  end

end
