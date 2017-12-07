require 'sinatra/base'
require_relative './extensions/checkouthelpers'
require_relative './extensions/paymentmethods'

class Checkout < Sinatra::Base

  helpers Sinatra::CheckoutHelpers
  helpers Sinatra::PaymentMethods
  
  enable :sessions	
  
  set :root, File.dirname(__FILE__)

  register Sinatra::PageFolders
  register Sinatra::SharedResources
  helpers  Sinatra::ViewHelpers
  register Sinatra::Auth

  before do
    headers['Location'] = request.url.sub('http', 'https')
    halt 301, "https required\n"
  end

  get('/plan/:id')                       { render_page :plan           }
  get('/pack/:id')                       { render_page :pack           }
  get('/training/:id')                   { render_page :training       }
  get('/event/:id')                      { render_page :event          }
  get('/complete')                       { render_page :complete       }
  get('/misc')                           { render_page :misc           }
  get('/front_desk')                     { render_page :front_desk     }
  get('/class_checkin')                  { render_page :class_checkin  } 
  get('/transactions')                   { render_page :transactions   }
  get('/class_sheet/:id')                { render_page :class_sheet    }
  get('/customer_file')                  { render_page :customer_file  }
  get('/class_reg/:id', :auth => 'user') { render_page :class_reg      }

  post('/plan/charge')       { buy_plan       }
  post('/pack/charge')       { buy_pack       }
  post('/pack/buy')          { buy_pack_precharged }
  post('/training/charge')   { buy_training   }
  post('/event/charge')      { buy_event      }
  post('/event/register')    { register_event }
  post('/misc/charge')       { buy_misc       }

  post('/charge_card')       { charge_card       }
  post('/charge_saved_card') { charge_saved_card }
  post('/pay_cash')          { pay_cash          }

  post('/swipe')             { card_swipe     }
  get('/wait_for_swipe')     { wait_for_swipe }

end