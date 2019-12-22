class GiftCertRoutes < Sinatra::Base

  before do
    cache_control :no_store
    content_type  :json
  end

  post '/' do
    cert = GiftCertificate::buy(params) or halt(500, "Gift Certificate Not Created")
    Slack.website_purchases(cert.purchase_description) 
    {}.to_json
  end

  post '/:code/redeem' do
    cert = GiftCertificate[:code => params[:code]] or halt(404,"Code Not Found")
    cert.redeem(params[:customer_id]) or halt(409,"Certificate Not Redeemed")
    {}.to_json
  end

  get '/:code/tall_image.jpg' do
    content_type 'image/jpeg'
    cert = GiftCertificate[:code => params[:code]] or halt(404,"Code Not Found")
    cert.tall_image.to_blob
  end

  error do
    Slack.err( 'GiftCert Route Error', env['sinatra.error'] )
    'An Error Occurred.'
  end

end