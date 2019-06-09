class PassRoutes < Sinatra::Base

  configure do
    set :start_time, Time.now
  end

  before do
    last_modified settings.start_time
    etag settings.start_time.to_s
    cache_control :no_cache
  end

  get '/all' do
    Pass.list_all
  end

  post '/compticket' do
    custy = Customer[params[:customer_id]]
    halt 404 if custy.nil?
    halt 409 if custy.comp_tickets.count > 0
    comp = CompTicket.create(:customer => custy)
    comp.redeem
    status 203
  end

end