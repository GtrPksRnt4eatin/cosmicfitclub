class HourlyRoutes < Sinatra::Base

  get '/shifts' do
    HourlyShift.where( :customer_id => params[:customer_id] ).to_json
  end

  get '/punches' do
    content_type :json
    custy = Customer[params[:customer_id]] or halt(404, "Cant Find Customer")
    HourlyPunch.where( :customer_id => params[ :customer_id ].to_i ).to_json
  end

  get '/my_punches' do
    content_type :json
    custy = session[:customer] or halt(404, "Not Signed In")
    HourlyPunch.where( :customer_id => custy.id ).order_by(:starttime).to_json
  end

  post '/punch_in' do
    custy = Customer[params[:customer_id]] or halt(404, "Cant Find Customer")
    punch = HourlyPunch[ :customer_id => custy.id, :endtime => nil ]
    halt(404, "Already Punched In") unless punch.nil? 
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