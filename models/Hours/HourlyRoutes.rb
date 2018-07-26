class HourlyRoutes < Sinatra::Base

  get '/shifts' do
    HourlySchedules.where( :customer_id => params[:customer_id] ).to_json
  end

  get '/punches' do
    HourlyPunch.where( :customer_id => params[:customer_id] ).to_json
  end

  post '/punch_in' do
  	HourlyPunch.create( 
  	  :customer_id => params[:customer_id], 
  	  :hourly_task_id => 1,
  	  :starttime => Time.now
  	)
  	status 204
  end

  post '/punch_out' do
  end

end