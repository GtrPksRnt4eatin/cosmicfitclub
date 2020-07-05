require 'braintree'

class BraintreeRoutes < Sinatra::Base

  ################################### CONFIG ####################################

  register Sinatra::Auth
  use JwtAuth
  
  configure do
    enable :cross_origin
    @@BT_GATEWAY = Braintree::Gateway.new(
      :environment => :production,
      :merchant_id => ENV["BRAINTREE_MERCH_ID"],
      :public_key => ENV["BRAINTREE_PUBLIC"],
      :private_key => ENV["BRAINTREE_PRIVATE"],
    )
  end

  before do
    cache_control :no_store
    response.headers['Access-Control-Allow-Origin'] = 'https://video.cosmicfitclub.com'
    response.headers['Access-Control-Allow-Credentials'] = 'true'
  end

  ################################### CONFIG ####################################

  get '/client_token' do
    return @@BT_GATEWAY.client_token.generate #unless session[:customer_id]
    #@@BT_GATEWAY.client_token.generate(:customer_id => session[:customer_id])
  end

  post "/checkout" do
    nonce = params[:payment_method_nonce]
    result = gateway.transaction.sale(
      :amount => "10.00",
      :payment_method_nonce => nonce,
      #:device_data => device_data_from_the_client,
      :options => {
        :submit_for_settlement => true
      }
    )
  end

end