class HourlyRoutes < Sinatra::Base

  get '/shifts' do
    HourlyShift.where( :customer_id => params[:customer_id] ).to_json
  end

  get '/punches' do
    HourlyPunch.where( :customer_id => params[:customer_id] ).to_json
  end

  post '/punch_in' do
  	HourlyPunch.create( 
  	  :customer_id => params[:customer_id], 
  	  :hourly_task_id => params[:hourly_task_id],
  	  :starttime => Time.now
  	)
  	status 204
  end

  post '/punch_out' do
  end

end