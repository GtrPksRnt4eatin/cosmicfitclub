class NfcTag < Sequel::Model

  many_to_one :customer
  
end

class NfcTagRoutes < Sinatra::Base

  post '/' do
  	tag = NfcTag[ :value => params[:value] ]
    tag.customer.to_json
  end

end