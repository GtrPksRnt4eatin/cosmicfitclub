require 'sinatra/base'
require_relative './extensions/checkouthelpers'

class Checkout < Sinatra::Base

  helpers Sinatra::CheckoutHelpers
  
  enable :sessions	
  
  set :root, File.dirname(__FILE__)

  register Sinatra::PageFolders
  register Sinatra::SharedResources
  helpers  Sinatra::ViewHelpers

  get('/plan/:id')      { render_page :plan     }
  get('/pack/:id')      { render_page :pack     }
  get('/complete')      { render_page :complete }
  get('/training')      { render_page :training }

  post('/plan/charge')     { buy_plan }
  post('/pack/charge')     { buy_pack }
  post('/training/charge') { buy_training }

end