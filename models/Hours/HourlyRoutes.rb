class HourlyRoutes < Sinatra::Base

  configure do
    set :start_time, Time.now
  end

  before do
    last_modified settings.start_time
    etag settings.start_time.to_s
    cache_control :no_cache
  end

  get '/shifts' do
    content_type :json
    HourlyShift.where( :customer_id => params[:customer_id] ).to_json
  end

  get '/punches' do
    content_type :json
    custy = session[:customer]                  or halt(401, "Not Signed In")
    HourlyPunch.where( :customer_id => params[ :customer_id ] ).to_json
  end

  get '/my_punches' do
    content_type :json
    custy = session[:customer]                  or halt(401, "Not Signed In")
    punches = HourlyPunch::punches(custy.id)
    p punches
    punches.to_json
  end

  post '/punch_in' do
    content_type :json
    custy = session[:customer]                  or halt(401, "Not Signed In")
    task  = HourlyTask[params[:hourly_task_id]] or halt(404, "Cant Find Hourly Task")
    HourlyPunch::punched_out?(custy.id)         or halt(409, "Punch Out First")
  	HourlyPunch::punch_in(custy.id,params[:hourly_task_id]).to_json
  end

  post '/punch_out' do
    content_type :json
    custy = session[:customer]                  or halt(401, "Not Signed In")
    punch = HourlyPunch::open_punch(custy.id)   or halt(409, "Not Punched In")
    punch.close.to_json
  end

end