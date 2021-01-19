class StaffRoutes < Sinatra::Base

  before do
    content_type :json
    cache_control :no_store
  end

  get '/' do
    JSON.generate Staff::ordered_list
  end

  get '/public_list' do
    JSON.generate Staff::public_list
  end

  get '/:id/details' do
    id = params[:id].to_i
    staff = Staff[id] or halt(404,"Can't Find Staff Account") 
    staff.full_details.to_json
  end

  get '/detail_list' do
    JSON.generate Staff::detail_list
  end

  get '/desk_staff' do
    JSON.generate Staff::desk_staff_list
  end
 
  post '/' do
  	max = Staff.max(:position)
  	halt 409 unless Staff[:name => params[:name]].nil?
    Staff.create(name: params[:name], title: params[:title], bio: params[:bio], image: params[:image], position: max ? max + 1 : 0 )
    status 200; {}.to_json
  end

  delete '/:id' do
    halt 404 if Staff[params[:id]].nil?
    Staff[params[:id]].deactivate
    status 200; {}.to_json
  end

  post '/:id' do
    staff = Staff[params[:id]] or halt(404,"Staff Not Found")
    staff.update(params[:values])
    status 204; {}.to_json
  end

  post '/:id/image' do
    staff = Staff[params[:id]] or halt(404,"Staff Not Found")
    staff.update( :image => params[:image] )
    status 204; {}.to_json
  end

  post '/:id/create_sub' do
    staff = Staff[params[:id]] or halt(404,"Staff Not Found")
    custy = staff.customer
    Subscription.create(:customer_id=>custy.id, :plan_id=>10 ).to_json
  end

  post '/:id/moveup' do
    staff = Staff[params[:id]] or halt(404, "Staff Not Found")
    staff.move(true)
    status 204; {}.to_json
  end

  post '/:id/movedn' do
    staff = Staff[params[:id]] or halt(404, "Staff Not Found")
    staff.move(false)
    status 204; {}.to_json
  end

  get '/payroll' do
    JSON.pretty_generate Staff::payroll(params[:from],params[:to])
  end

  get '/payroll.csv' do
    content_type 'application/csv'
    attachment "Payroll #{params[:from]}.csv"
    csv = Staff::payroll_csv(params[:from],params[:to])
    csv.string
  end

end