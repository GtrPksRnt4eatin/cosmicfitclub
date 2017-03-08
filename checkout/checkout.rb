require 'sinatra/base'
require_relative './extensions/checkouthelpers'

class Checkout < Sinatra::Base

  helpers Sinatra::CheckoutHelpers
  
  enable :sessions	
  
  set :root, File.dirname(__FILE__)

  register Sinatra::PageFolders
  register Sinatra::SharedResources
  helpers  Sinatra::ViewHelpers
  register Sinatra::Auth

  get('/plan/:id')      { render_page :plan     }
  get('/pack/:id')      { render_page :pack     }
  get('/training/:id')  { render_page :training }
  get('/event/:id')     { render_page :event    }
  get('/complete')      { render_page :complete }

  post('/plan/charge')     { buy_plan     }
  post('/pack/charge')     { buy_pack     }
  post('/training/charge') { buy_training }
  post('/event/charge')    { buy_event    }

end