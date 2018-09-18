require 'sinatra/base'

class CFCFrontDesk < Sinatra::Base

  set :root, File.dirname(__FILE__)

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  register Sinatra::Auth

  get( '/waterfront_deal') { render_page :waterfront_deal }

  not_found do
    'This is nowhere to be found.'
  end

  error do
    Slack.post("Offers Error:\r\r#{env['sinatra.error'].message}\r\r#{env['sinatra.error'].backtrace.join("\r")}" )
    'An Error Occurred.'
  end

end
