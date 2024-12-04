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
    NfcTag.all.map(&:detail_view).to_json
  end

end