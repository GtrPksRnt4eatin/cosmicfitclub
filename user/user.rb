require 'sinatra/base'

class CFCuser < Sinatra::Base
  
  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  register Sinatra::Auth

  set :public_folder, File.dirname(__FILE__)

  get( '/', :auth => 'user' ) { ref_cust; render_page :user } 

end