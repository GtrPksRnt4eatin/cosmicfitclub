require 'sinatra/base'

class ConfirmSSL < Sinatra::Base

  set :bind, '0.0.0.0'
  set :port, 80

  get '/' do
    "hello"
  end

  get '/.well-known/acme-challenge/*' do
  	"8mECZTcBI-laWb4rqsWtyLYDRFGAcsR3aEw7FtluMyg.dRiPVRVuJw1WfdUhrZtSmTwczgs27JHL1f2fbdc_ncA"
  end

end

ConfirmSSL.run!