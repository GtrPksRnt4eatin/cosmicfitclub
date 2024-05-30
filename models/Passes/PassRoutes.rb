class PassRoutes < Sinatra::Base

  ################################### CONFIG ####################################

  register Sinatra::Auth
  use JwtAuth

  configure do
    enable :cross_origin
  end

  before do
    cache_control :no_store
    origin_ok = ['https://video.cosmicfitclub.com', 'https://localhost:3000'].include? request.env["HTTP_ORIGIN"]
    response.headers['Access-Control-Allow-Origin'] = request.env["HTTP_ORIGIN"] if origin_ok
    response.headers['Access-Control-Allow-Credentials'] = 'true'
  end

  ################################### CONFIG ####################################

  get '/all' do
    Pass.list_all
  end

  get '/packages' do
    Package.where(:available=>true).reverse_order(:num_passes).all.to_json
  end

  get '/packages/front_desk' do
    Package.where(:available_at_desk => true).reverse_order(:num_passes).all.to_json
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

  delete '/transactions/:id' do
    trans = PassTransaction[params[:id]] or halt(404,"Couldn't find transaction")
    trans.undo
  end

end
