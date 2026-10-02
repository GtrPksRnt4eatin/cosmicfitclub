require 'rqrcode'

class QrCodeRoutes < Sinatra::Base

  # GET /?url=<url-encoded-url>
  # Returns a PNG image of the QR code for the provided `url` parameter.
  get '/' do
    url = params['url'] || params[:url]
    halt 400, "missing url" if url.nil? || url.to_s.strip.empty?

    begin
      qrcode = RQRCode::QRCode.new(url)
      png = qrcode.as_png(size: 300)
      content_type 'image/png'
      body png.to_blob
    rescue StandardError => e
      status 400
      body "invalid url or could not generate QR: #{e.message}"
    end
  end

end
