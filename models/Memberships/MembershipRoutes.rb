class MembershipRoutes < Sinatra::Base

  post '/' do
    custy = Customer.find_by_email(params[:email]) or halt 404, 'No account found to add subscription to'
    plan = Plan[ :stripe_id => params[:plan_id]] or halt 404, 'Plan id did not link to a valid plan'
    Subscription.create({ :customer => custy, :plan => plan, :stripe_id => params[:stripe_id] })
  end

  get '/:id/details' do
    content_type :json
    Subscription[params[:id]].details.to_json
  end

  get '/:id/invoices' do
    content_type :json
    Subscription[params[:id]].invoices.to_json
  end

  get '/:id/stripe_info' do
    content_type :json
    Subscription[params[:id]].stripe_info
  end

  get '/:id/uses' do
    content_type :json
    Subscription[params[:id]].uses.to_json
  end

  delete '/:id' do
    sub = Subscription[params[:id]] or halt 404
    sub.delete
  end

  post '/:id/stripe_id' do
    sub = Subscription[params[:id]] or halt 404
    sub.update( :stripe_id => params[:value] )
  end

  get '/list' do
    content_type :json
    Subscription::list_all.to_json
  end

  get '/matched_list' do
    stripe_list = Stripe::Subscription.list(:limit=>100).data
    cosmic_list = Subscription.where( :deactivated => false ).all

    cosmic_free, cosmic_list = cosmic_list.partition { |x| x.plan.free == true }

    stripe_list.map! do |sub|
      {  :id => sub[:id],
         :customer => Stripe::Customer.retrieve(sub[:customer]),
         :plan_id => sub[:plan].id,
         :plan_name => sub[:plan].name,
         :matched => cosmic_list.find { |x| x.stripe_id == sub[:id] }
      }
    end

    cosmic_list.map! do |sub|
      {  :id => sub.id,
         :customer_id => sub.customer.nil? ? 0 : sub.customer.id,
         :customer => sub.customer.nil? ? '' : sub.customer.name,
         :plan_name => sub.plan.name,
         :stripe_id => sub.stripe_id,
         :matched => stripe_list.find { |x| x[:id] == sub.stripe_id }
      }
    end

    cosmic_free.map! do |sub|
      {  :id => sub.id,
         :customer_id => sub.customer.nil? ? 0 : sub.customer.id,
         :customer => sub.customer.nil? ? '' : sub.customer.name,
         :plan_name => sub.plan.name
      }
    end

    cosmic_unmatched, cosmic_matched = cosmic_list.partition { |x| x[:matched].nil? }
    stripe_unmatched, stripe_matched = stripe_list.partition { |x| x[:matched].nil? }

    stripe_matched.sort_by! { |x| [ x[:plan_name], x[:id] ] }
    cosmic_matched.sort_by! { |x| [ x[:plan_name], x[:stripe_id] ] }

    { :cosmic_free => cosmic_free,
      :cosmic_unmatched => cosmic_unmatched,
      :stripe_unmatched => stripe_unmatched,
      :cosmic_matched => cosmic_matched,
      :stripe_matched => stripe_matched
    }.to_json

  end

end