require 'sinatra/base'
require_relative './extensions/checkouthelpers'
require_relative './extensions/paymentmethods'

class Checkout < Sinatra::Base

  helpers Sinatra::CheckoutHelpers
  helpers Sinatra::PaymentMethods
  
  set :root, File.dirname(__FILE__)

  configure do
    set :start_time, Time.now
  end

  before do
    last_modified settings.start_time
    etag settings.start_time.to_s
    cache_control :no_cache
  end
  

  register Sinatra::PageFolders
  register Sinatra::SharedResources
  helpers  Sinatra::ViewHelpers
  register Sinatra::Auth

  get('/plan/:id')                               { render_page :plan           }
  get('/pack/:id')                               { render_page :pack           }
  get('/training/:id')                           { render_page :training       }
  get('/event/:id')                              { render_page :event          }
  get('/event2/:id')                             { render_page :event2         }  
  get('/complete')                               { render_page :complete       }
  get('/misc')                                   { render_page :misc           }
  get('/front_desk')                             { render_page :front_desk     }

  get('/transactions')                           { render_page :transactions   }

  get('/class_reg/:id',   :auth => 'user')       { render_page :class_reg      }

  get('/class_checkin',   :auth => 'frontdesk' ) { render_page :class_checkin  } 
  get('/class_sheet/:id', :auth => 'frontdesk' ) { render_page :class_sheet    }
  get('/customer_file',   :auth => 'frontdesk' ) { render_page :customer_file  }

  post('/plan/charge')       { buy_plan             }
  post('/pack/charge')       { buy_pack             }
  post('/pack/buy')          { buy_pack_precharged  }
  post('/training/charge')   { buy_training         }
  post('/event/precharged')  { buy_event_precharged }
  post('/event/charge')      { buy_event            }
  post('/event/register')    { register_event       }
  post('/misc/charge')       { buy_misc             }

  post('/charge_card')       { charge_card         }
  post('/charge_saved_card') { charge_saved_card   }
  post('/pay_cash')          { pay_cash            }

  post('/swipe')             { card_swipe          }

  get('/wait_for_swipe',    :auth => 'frontdesk' ) { wait_for_swipe      }

  post('/save_card',        :self_or => 'frontdesk' ) { save_card           }
  post('/set_default_card', :self_or => 'frontdesk' ) { set_default_card    }
  post('/remove_card',      :self_or => 'frontdesk' ) { remove_card         }

  #error 401 do
  #  render_page :error
  #end

  #error 404 do
  #  render_page :error
  #end

  error do
    Slack.err( 'Checkout Error', env['sinatra.error'] )
    'An Error Occurred.'
    render_page :error
  end

end