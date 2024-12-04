require 'rest-client'

class NfcTagRoutes < Sinatra::Base

  before do
    content_type :json
    cache_control :no_store
    origin_ok = ['https://video.cosmicfitclub.com', 'https://localhost:3000'].include? request.env["HTTP_ORIGIN"]
    response.headers['Access-Control-Allow-Origin'] = request.env["HTTP_ORIGIN"] if origin_ok
    response.headers['Access-Control-Allow-Credentials'] = 'true'
  end

  get '/all' do
    NfcTag.order(:customer_id).all.map(&:detail_view).to_json
  end

  post '/' do
    customer = Customer[params[:customer_id]] or halt(404,"Can't find customer")
    NfcTag.create(customer_id: params[:customer_id], value: params[:value])
    status 204
  end

  delete '/:id' do
    tag = NfcTag[params[:id]] or halt(404, "Can't find tag")
    tag.delete
    status 204
  end

end