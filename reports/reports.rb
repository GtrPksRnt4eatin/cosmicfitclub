require 'sinatra/base'
require_relative './extensions/report_queries'

class Reports < Sinatra::Base

  #enable :sessions
  set :root, File.dirname(__FILE__)

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  register Sinatra::Auth
  helpers  Sinatra::ReportQueries
  register Sinatra::ReportQueries

  get( '/', )                                     { render_page :index         }
  get( '/pass_balances', :auth => 'reports' )     { render_page :pass_balances }
  get( '/subscriptions', :auth => 'reports' )     { render_page :subscriptions }
  get( '/email_lists',   :auth => 'reports' )     { render_page :email_lists   }
  get( '/attendence',    :auth => 'reports' )     { render_page :attendence    }

end
