class RentalRoutes < Sinatra::Base

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
    p params
    p params[:id]
    if params[:id]==0 then
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