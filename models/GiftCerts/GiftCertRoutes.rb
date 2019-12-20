class GiftCertRoutes < Sinatra::Base

  before do
    cache_control :no_store
    content_type  :json
  end

  post '/' do
    GiftCertificate::buy(params)
    {}.to_json
  end

  post '/:code/redeem' do
    cert = GiftCertificate[params[:code]] or halt(404,"Code Not Found")
    cert.redeem(params[:customer_id]) or halt(409,"Certificate Not Redeemed")
    {}.to_json
  end

  get '/:code/tall_image.jpg' do
    content_type :image/jpeg
  end

end