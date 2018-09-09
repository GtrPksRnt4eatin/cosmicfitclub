class HourlyRoutes < Sinatra::Base

  get '/shifts' do
    HourlyShift.where( :customer_id => params[:customer_id] ).to_json
  end

  get '/punches' do
    p params[ :customer_id ]
    p HourlyPunch.where( :customer_id => params[ :customer_id ].to_i )
    HourlyPunch.where( :customer_id => params[ :customer_id ].to_i ).to_json
  end

  post '/punch_in' do
    custy = Customer[params[:id]] or halt(404, "Cant Find Customer")
    
  	HourlyPunch.create( 
  	  :customer_id => custy.id, 
  	  :hourly_task_id => params[:hourly_task_id],
  	  :starttime => Time.now
  	)
  	status 204
  end

  post '/punch_out' do
  end

end