module Sinatra
  module CheckoutHelpers

    def buy_plan
      data = JSON.parse request.body.read
      customer = Customer.get_from_token( data['token'] )
      halt 409 if customer.plan != nil                       ## Already Has A Plan, Log in to Update instead
      customer.add_subscription( data['plan_id'] )
      status 204
    end

    def buy_pack
      data = JSON.parse request.body.read
      customer = Customer.get_from_token( data['token'] )
      customer.buy_pack( data['pack_id'], data['token'] )
      status 204
    end

    def buy_training
      data = JSON.parse request.body.read
      customer = Customer.get_from_token( data['token'] )
      customer.buy_training( data['num_hours'], 1, data['token'], data['trainer'] )
      status 204
    end
  
  end
end