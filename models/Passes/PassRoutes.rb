class PassRoutes < Sinatra::Base

  ################################### CONFIG ####################################

  register Sinatra::Auth
  use JwtAuth

  configure do
    enable :cross_origin
  end

  before do
    cache_control :no_store
    response.headers['Access-Control-Allow-Origin'] = 'https://video.cosmicfitclub.com'
    response.headers['Access-Control-Allow-Credentials'] = 'true'
  end

  ################################### CONFIG ####################################

  get '/all' do
    Pass.list_all
  end

  get '/packages' do
    Package.where(:available=>true).reverse_order(:num_passes).all.to_json
  end

  post '/compticket' do
    custy = Customer[params[:customer_id]]
    halt 404 if custy.nil?
    halt 409 if custy.comp_tickets.count > 0
    comp = CompTicket.create(:customer => custy)
    comp.redeem
    status 203
  end

  delete '/wallet/:id' do
    wallet = Wallet[params[:id]] or halt(404,"Couldn't find wallet")
    wallet.force_delete
  end

end