class MembershipRoutes < Sinatra::Base

  get '/'  do
  	
  end

  get '/:id' do
    
  end

  get '/:id/details' do
    Subscription[params[:id]].stripe_info
  end

end