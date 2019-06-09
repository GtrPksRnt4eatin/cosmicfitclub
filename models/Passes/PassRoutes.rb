class PassRoutes < Sinatra::Base

  before do
    cache_control :no_store
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