class HourlyRoutes < Sinatra::Base

  before do
    cache_control :no_store
    content_type :json
  end

  get '/shifts' do
    HourlyShift.where( :customer_id => params[:customer_id] ).to_json
  end

  get '/punches' do
    custy = session[:customer]                  or halt(401, "Not Signed In")
    HourlyPunch.where( :customer_id => params[ :customer_id ] ).to_json
  end

  get '/open_punches' do
    HourlyPunch::open_punches.to_json
  end

  get '/my_punches' do
    custy = session[:customer]                  or halt(401, "Not Signed In")
    punches = HourlyPunch::punches(custy.id)
    punches.to_json
  end

  post '/punch_in' do
    custy = session[:customer]                  or halt(401, "Not Signed In")
    task  = HourlyTask[params[:hourly_task_id]] or halt(404, "Cant Find Hourly Task")
    HourlyPunch::punched_out?(custy.id)         or halt(409, "Punch Out First")
  	HourlyPunch::punch_in(custy.id,params[:hourly_task_id]).to_json
  end

  post '/punch_out' do
    custy = session[:customer]                  or halt(401, "Not Signed In")
    punch = HourlyPunch::open_punch(custy.id)   or halt(409, "Not Punched In")
    punch.close.to_json
  end

end