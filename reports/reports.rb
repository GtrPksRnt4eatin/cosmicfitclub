require 'sinatra/base'
require_relative './extensions/report_queries'

class Reports < Sinatra::Base

  enable :sessions	
  set :root, File.dirname(__FILE__)

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  register Sinatra::Auth
  register Sinatra::ReportQueries

  get( '/', )                               { render_page :index         }
  get( '/pass_balances', :auth => 'admin' ) { render_page :pass_balances }
  get( '/subscriptions', :auth => 'admin' ) { render_page :subscriptions }
  get( '/email_lists',   :auth => 'admin' ) { render_page :email_lists   }

end
