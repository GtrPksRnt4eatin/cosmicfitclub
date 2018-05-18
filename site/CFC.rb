require 'sinatra/base'

class CFC < Sinatra::Base

  #enable :sessions

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  register Sinatra::Auth

  set :root, File.dirname(__FILE__)

  get( '/' )                 { render_page :index    } 
  get( '/classes')           { render_page :classes  }
  get( '/training')          { render_page :training }
  get( '/events')            { render_page :events   }
  get( '/schedule')          { render_page :schedule }
  get( '/staff')             { render_page :staff    }
  get( '/pricing')           { render_page :pricing  }
  get( '/faq')               { render_page :faq      }
  get( '/kids')              { render_page :kids     }
  get( '/media')             { render_page :media    }

  get( '/schedule_week')     { render_page :schedule_week }

  get( '/waiver', :auth => 'user' ) { render_page :waiver }
  get( '/user'  , :auth => 'user' ) { ref_cust; render_page :user   }

  get( '/checkout')               { render_page :checkout }
  get( '/checkout/plans/:id' )    { render_page :checkout_plan }
  get( '/checkout/packages/:id' ) { render_page :checkout_pack }
  get( '/checkout/complete')      { render_page :checkout_complete }

  get( '/login' ) { redirect('/auth/login') }

  get( '/gmb' ) { redirect('/checkout/event/226') }

  get( '/resetData' ) do
    $DB[:waivers].truncate( :restart=>true )
    $DB[:customers].truncate( :restart=>true )
    $DB[:omniaccounts].truncate(:restart=>true )
    $DB[:passes].truncate( :restart=>true )
    $DB[:roles_users].truncate( :restart=>true )
    $DB[:subscriptions].truncate( :restart=>true )
    $DB[:users].truncate( :restart=>true, :cascade=>true )
    $DB[:training_passes].truncate( :restart=>true )
    StripeMethods::sync_plans
    StripeMethods::sync_packages
    StripeMethods::sync_training
    return 200
  end

  post( '/waiver', :auth => 'user' ) do
    session[:customer].waiver = Waiver.create(:signature => request.body.read )
    return 204
  end

  get( '/waiver.svg', :auth => 'user' ) do
    return session[:customer].waiver
  end
  
end 