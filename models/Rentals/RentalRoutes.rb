class RentalRoutes < Sinatra::Base

  configure do
    set :start_time, Time.now
  end

  before do
    last_modified settings.start_time
    etag settings.start_time.to_s
    cache_control :no_cache
  end

  get '/' do
  	content_type :JSON
  	JSON.generate( Rental.upcoming )
  end

  get '/past' do
  	content_type :JSON
    JSON.generate( Rental.past )
  end

  get '/:id' do
    content_type :JSON
    rental = Rental[params[:id]] or halt 404
    JSON.generate( rental )
  end

  post '/' do
    if params[:id].to_i==0 then
      Rental.create( :start_time => params[:start_time], :duration_hours => params[:duration_hours], :title => params[:title] ).to_json
    else
      rental = Rental[params[:id]] or halt 404
      rental.update( :start_time => params[:start_time], :duration_hours => params[:duration_hours], :title => params[:title] ).to_json
    end
  end

  delete '/:id' do
    rental = Rental[params[:id]] or halt 404
    rental.delete
    status 204
  end

end