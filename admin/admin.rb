require 'sinatra/base'

class CFCAdmin < Sinatra::Base

  set :root, File.dirname(__FILE__)

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  register Sinatra::Auth

  configure do
    set :start_time, Time.now
  end

  before do
    last_modified settings.start_time
    etag settings.start_time.to_s
    cache_control :no_cache
  end
  
  get( '/',                      :auth=> 'admin'      ) { render_page :index             }
  get( '/carousel',              :auth=> 'admin'      ) { render_page :carousel          }
  get( '/classes',               :auth=> 'admin'      ) { render_page :classes           }
  get( '/events',                :auth=> 'admin'      ) { render_page :events            }
  get( '/staff',                 :auth=> 'admin'      ) { render_page :staff             }
  get( '/staff_list',            :auth=> 'admin'      ) { render_page :staff_list        }
  get( '/staff_detail',          :auth=> 'admin'      ) { render_page :staff_detail      }
  get( '/events/:id',            :auth=> 'admin'      ) { render_page :event_edit        }
  get( '/events/:id/accounting', :auth=> 'admin'      ) { render_page :event_accounting  }
  get( '/classes/:id',           :auth=> 'admin'      ) { render_page :class_edit        }
  get( '/door',                  :auth=> 'door'       ) { render_page :door              }
  get( '/balance',               :auth=> 'admin'      ) { render_page :balance_sheet     }
  get( '/announcements',         :auth=> 'admin'      ) { render_page :announcements     }
  get( '/subscription_list',     :auth=> 'admin'      ) { render_page :subscription_list }
  get( '/subscription',          :auth=> 'admin'      ) { render_page :subscription      }
  get( '/kids_slides'                                 ) { render_page :kids_slides       }
  get( '/member_match'                                ) { render_page :member_match      }   
  get( '/class_exceptions',      :auth=> 'admin'      ) { render_page :class_exceptions  }     
  get( '/roles'                                       ) { render_page :roles             }
  get( '/rentals',               :auth=> 'admin'      ) { render_page :rentals           }
  get( '/merge',                                      ) { render_page :merge_customers   }
  get( '/cameras',               :auth=> 'admin'      ) { render_page :cameras           }
  get( '/hourly',                :auth=> 'admin'      ) { render_page :hourly_shifts     }
  get( '/edit_ticket',           :auth=> 'admin'      ) { render_page :edit_ticket       }
  get( '/tickets/:id',           :auth=> 'admin'      ) { render_page :edit_ticket       }
  get( '/payment_sources',       :auth=> 'admin'      ) { render_page :payment_sources   }

  get( '/payroll',               :auth=> 'payroll'    ) { render_page :payroll           }
  
  get( '/console',               :auth=> 'admin'      ) { render_page :console           }

  post( '/console',              :auth=> 'admin'      ) do
    x = eval(request.body.read)
    x.to_s
  rescue Exception => e
    e.message + "\r\n\r\n" + e.backtrace.join("\r\n")
  end

  not_found do
    'This is nowhere to be found.'
  end

  error do
    Slack.err( 'Admin Error', env['sinatra.error'] )
    'An Error Occurred.'
  end


end 