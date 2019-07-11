class StaffRoutes < Sinatra::Base

  before do
    cache_control :no_store
  end

  get '/' do
    content_type :json
    JSON.generate Staff::ordered_list
  end

  get '/:id/details' do
    content_type :json
    id = params[:id].to_i
    staff = Staff[id] or halt(404,"Can't Find Staff Account") 
    staff.full_details.to_json
  end

  get '/detail_list' do
    content_type :json
    JSON.generate Staff::detail_list
  end
 
  post '/' do
  	max = Staff.max(:position)
  	halt 409 unless Staff[:name => params[:name]].nil?
    Staff.create(name: params[:name], title: params[:title], bio: params[:bio], image: params[:image], position: max ? max + 1 : 0 )
    status 200
  end

  delete '/:id' do
    halt 404 if Staff[params[:id]].nil?
    Staff[params[:id]].deactivate
    status 200
  end

  post '/:id' do
    staff = Staff[params[:id]] or halt(404,"Staff Not Found")
    staff.update(params[:values])
  end

  post '/:id/moveup' do
    staff = Staff[params[:id]] or halt(404, "Staff Not Found")
    staff.move(true)
  end

  post '/:id/movedn' do
    staff = Staff[params[:id]] or halt(404, "Staff Not Found")
    staff.move(false)
  end

  get '/payroll' do
    JSON.pretty_generate Staff::payroll(params[:from],params[:to])
  end

  get '/payroll.csv' do
    content_type 'application/csv'
    attachment "Payroll #{params[:from]}.csv"
    proll = Staff::payroll(params[:from],params[:to])
    csv_string = CSV.generate do |csv|
      csv << [ 'Payroll' ]
      csv << [ 'Start Date', params[:from] ]
      csv << [ 'End Date', params[:to] ]
      csv << []
      grand_total = 0
      proll.each do |teacher_row|
        total = 0
        csv << [ teacher_row[:staff_name].upcase, "#{params[:from]} to #{params[:to]}" ]
        csv << [ 'DATE', 'CLASSNAME', 'HEADCOUNT', 'PAY' ]
        csv << []
        teacher_row[:class_occurrences].each do |row|
          csv << [ Time.parse(row['starttime']).strftime("%a %m/%d %l:%M %P"), row['class_name'], row['headcount'], row[:pay] ] unless row['class_name'].nil?
          csv << [ row[:timerange], row[:task], row[:hours], row[:pay] ] if row['class_name'].nil?
          total = total + row[:pay]
        end
        grand_total = grand_total + total
        csv << [ ]
        csv << [ '','', 'TOTAL', "$ %.2f" % total ]
        csv << []
      end
      csv << [ '', '', 'GRAND TOTAL', "$ %.2f" % grand_total ]
    end
  end

end