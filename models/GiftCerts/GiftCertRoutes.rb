class GiftCertRoutes < Sinatra::Base

  register Sinatra::Auth

  before do
    cache_control :no_store
    content_type  :json
  end

  post '/' do
    cert = GiftCertificate::buy(params) or halt(500, "Gift Certificate Not Created")
    {}.to_json
  end

  post '/:code/redeem' do
    cert = GiftCertificate[:code => params[:code]] or halt(404,"Code Not Found")
    logged_in?                                     or halt(401,"Not Logged In")
    cert.redeem(customer.id)                       or halt(409,"Certificate Not Redeemed")
    {}.to_json
  end

  get '/:code/tall_image.jpg' do
    cert = GiftCertificate[:code => params[:code]] or halt(404,"Code Not Found")
    content_type cert.tall_image.image.mime_type
    send_file cert.tall_image.image.download.path
  end

  error do
    Slack.err( 'GiftCert Route Error', env['sinatra.error'] )
    'An Error Occurred.'
  end

end