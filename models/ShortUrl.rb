class ShortUrl < Sequel::Model

  one_to_one :event

end

class ShortUrlRoutes < Sinatra::Base

  get '/' do
    content_type :json
  	JSON.generate ShortUrl.all
  end

  post '/' do
    ShortUrl.create( long_path: params[:long_path], short_path: params[:short_path] )
  end

  delete '/:id' do
    halt 404 if ShortUrl[params[:id]].nil?
    ShortUrl[params[:id]].destroy
    status 200
  end

end