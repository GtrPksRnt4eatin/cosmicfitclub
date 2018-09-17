require 'sinatra/base'

class CFCAdmin < Sinatra::Base

  set :root, File.dirname(__FILE__)

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  register Sinatra::Auth
  
  get( '/',                      :auth=> 'admin'      ) { render_page :index            }
  get( '/carousel',              :auth=> 'admin'      ) { render_page :carousel         }
  get( '/classes',               :auth=> 'admin'      ) { render_page :classes          }
  get( '/events',                :auth=> 'admin'      ) { render_page :events           }
  get( '/staff',                 :auth=> 'admin'      ) { render_page :staff            }
  get( '/events/:id',            :auth=> 'admin'      ) { render_page :event_edit       }
  get( '/events/:id/accounting', :auth=> 'admin'      ) { render_page :event_accounting }
  get( '/classes/:id',           :auth=> 'admin'      ) { render_page :class_edit       }
  get( '/door',                  :auth=> 'door'       ) { render_page :door             }
  get( '/balance',               :auth=> 'admin'      ) { render_page :balance_sheet    }
  get( '/announcements',         :auth=> 'admin'      ) { render_page :announcements    }
  get( '/member_list'                                 ) { render_page :member_list      }
  get( '/kids_slides'                                 ) { render_page :kids_slides      }
  get( '/member_match'                                ) { render_page :member_match     }   
  get( '/class_exceptions',      :auth=> 'admin'      ) { render_page :class_exceptions }     
  get( '/roles'                                       ) { render_page :roles            }
  get( '/rentals',               :auth=> 'admin'      ) { render_page :rentals          }
  get( '/merge',                                      ) { render_page :merge_customers  }
  get( '/cameras',               :auth=> 'admin'      ) { render_page :cameras          }
  get( '/hourly',                :auth=> 'admin'      ) { render_page :hourly_shifts    }
  get( '/tickets/:id',           :auth=> 'admin'      ) { render_page :edit_ticket      }
  
  get( '/console',               :auth=> 'admin'      ) { render_page :console          }

  post( '/console',              :auth=> 'admin'      ) { x = request.body.read; p x; x = eval(x); p x; x.to_s }

end 