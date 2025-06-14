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
    pass if params[:id].to_i == 0
    staff = Staff[params[:id]] or halt(404,"Staff Not Found")
    p params[:values]
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

  get '/payroll_reports' do
    Payroll.where { start_date >= (Date.today-365)}.order(:start_date).map(&:details_hash).to_json
  end
  
  get '/payroll2drive' do 
    { :url => Sheets::create_payroll_sheet(params[:from],params[:to]) }.to_json
  end

  post '/payroll' do
    data = Staff::payroll(params[:from],params[:to])
    proll = Payroll.create({ start_date: params[:from], end_date: params[:to]})
    data.each do |row|
      slip = PayrollSlip.create({ staff_id: row[:staff_id], payroll_id: proll.id})
      row[:class_occurrences].each do |line|
        PayrollLine.create({ 
          payroll_slip_id: slip.id,
          class_occurrence_id: line[:id],
          start_time: line[:starttime],
          description: line[:class_name],
          quantity: line[:headcount],
          category: "class_pay",
          value: line[:pay],
          cosmic: line[:cosmic],
          loft: line[:loft],
          loft_rentals: line[:loft_rentals],
          loft_classes: line[:loft_classes]
        })
      end
    end
    JSON.generate proll
  end

  post '/payout' do  
    result = StripeMethods::PayoutVendor(params[:amount], params[:stripe_connected_acct], params[:descriptor])
    payout = Payout.create({
      :stripe_transfer_id => result[:transfer].try(:id),
      :stripe_payout_id   => result[:payout].id,
      :date               => Time.at(result[:payout]['created']),
      :amount             => params[:amount],
      :payroll_id         => params[:payroll_id],
      :payroll_slip_id    => params[:slip_id],
      :staff_id           => params[:staff_id],
      :tag                => params[:tag]
    })
    payout.payroll_slip.send_email if payout.payroll_slip
    payout.to_json
  end

  get '/paypal' do
    data = PayPalSDK::list_transactions(params[:from],params[:to])
    data.map! do |x|
      payment = CustomerPayment.where( :paypal_id => x[:id] ).first
      x.merge({
        :customer    => Customer.find_by_email(x[:email]).try(:to_token),
        :payment     => payment,
        :reservation => payment.try(:reservation) 
      })
    end
    JSON.pretty_generate data
  end

  get '/payroll.csv' do
    content_type 'application/csv'
    attachment "Payroll #{params[:from]}.csv"
    csv = Staff::payroll_csv(params[:from],params[:to])
    csv.string
  end

  get '/paypal.csv' do
    content_type 'application/csv'
    attachment "PayPal #{params[:from]}-#{params[:to]}.csv"
    csv = PayPalSDK::list_transactions_csv(params[:from],params[:to])
    csv.string
  end

  get '/payouts.csv' do
    content_type 'application/csv'
    attachment "Payouts #{params[:from]}-#{params[:to]}.csv"
    csv = Staff::payouts_csv(params[:from],params[:to])
    csv.string
  end

end
