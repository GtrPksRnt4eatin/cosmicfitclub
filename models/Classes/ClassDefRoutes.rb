class ClassDefRoutes < Sinatra::Base

  get '/' do
    data = ClassDef.exclude(:deactivated=>true).order(:position).all.map do |c| 
      { :id => c.id, 
        :name => c.name, 
        :description => c.description,
        :image_url => (  c.image.nil? ? '' : ( c.image.is_a?(ImageUploader::UploadedFile) ? c.image_url : c.image[:small].url ) ),
        :schedules => c.schedules
      }
    end
    JSON.generate data
  end

  post '/' do
    if ClassDef[params[:id]].nil?
      classdef = ClassDef.create(name: params[:name], description: params[:description], image: params[:image], position: ClassDef.max(:position) + 1)
    else
      classdef = ClassDef[params[:id]]
      classdef.update_fields(params, [ :name, :description ] )
      classdef.update( :image => params[:image] ) unless params[:image].nil?
    end
    status 200
    classdef.to_json
  end

  delete '/:id' do
    halt 404 if ClassDef[params[:id]].nil?
    ClassDef[params[:id]].deactivate
    status 200
  end

  get '/:id/thumb' do
    classdef = ClassDef[params[:id]] or halt 404
    content_type classdef.image[:small].mime_type
    send_file classdef.image[:small].download.path
  end

  post '/:id/moveup' do
    classdef = ClassDef[params[:id]] or halt 404
    classdef.move(true)
    status 200
  end

  post '/:id/movedn' do
    classdef = ClassDef[params[:id]] or halt 404
    classdef.move(false)
    status 200
  end

  get '/:id/schedule' do
    content_type :json
    classdef = ClassDef[params[:id]] or halt 404, 'class definition not found'
    from = ( params[:from] or DateTime.now.beginning_of_day.to_time )
    to = ( params[:to] or Time.now.months_since(6) )
    JSON.generate classdef.get_full_occurences(from, to)
  end

  post '/:id/schedules' do
    data = JSON.parse(request.body.read)
    id = data['id']
    data.delete('id')
    schedule = ClassDef[params[:id]].create_schedule(data) if id == 0 
    schedule = ClassdefSchedule[id].update(data)       unless id == 0
    Slack.post("#{session[:customer].name} changed the class schedule: \r\n#{schedule.description_line}")
    schedule.to_json
  end 

  delete '/schedules/:id' do
    id = Integer(params[:id])         rescue halt(401, "ID Must Be Numeric" )
    sched = ClassdefSchedule[params[:id]] or halt(404, "Schedule Not Found" )
    Slack.post("#{session[:customer].name} changed the class schedule: \r\n removed #{sched.description_line} from the schedule")
    sched.destroy
    status 204
  end

  get '/schedule/:start/:end' do
    items = []
    ClassdefSchedule.all.each do |sched|
      sched.get_occurences(params[:start], params[:end]).each do |starttime|
        items << { 
          :day => Date.strptime(starttime.to_time.iso8601).to_s,
          :starttime => starttime,
          :endtime => sched.end_time,
          :title => sched.classdef.name,
          :classdef_id => sched.classdef.id,
          :sched_id => sched.id,
          :instructors => sched.teachers,
          :headcount => ClassOccurrence.get_headcount( sched.classdef.id, sched.teachers[0].id, starttime.to_time.iso8601 ),
          :capacity => sched.capacity
        }
      end
    end
    items = items.group_by { |x| x[:day] }
    arr = []
    items.each { |k,v| arr << { :day => k, :occurrences => v.sort_by { |x| x[:starttime] } } }
    JSON.generate arr.sort_by { |x| x[:day] }
  end

  get '/occurrences' do
    day = params[:day].nil? ? Date.today : Date.parse(params[:day])
    sheets = ClassOccurrence.where{ |o| (o.starttime >= day) & (o.starttime < day + 1)}.order(:starttime).all.map do |occ|
      { 
        :id           => occ.id,
        :starttime    => occ.starttime.to_time.iso8601,
        :classdef     => { :id => occ.classdef.id, :name => occ.classdef.name },
        :teacher      => { :id => occ.teacher.id, :name => occ.teacher.name },
        :reservations => occ.reservation_list
      }
    end
    JSON.generate sheets
  end   

  post '/occurrences' do
    content_type :json
    occurrence = ClassOccurrence.get(params['classdef_id'], params['staff_id'], params['starttime'] )
    occurrence.to_full_json
  end

  post '/occurrences/:id' do
    content_type :json
    id = Integer(params[:id])        rescue halt(401, "ID Must Be Numeric")
    occurrence = ClassOccurrence[id]     or halt(404, "Occurrence Doesn't Exist")
    p params
    occurrence.update( :staff_id=>params[:staff_id], :classdef_id=>params[:classdef_id], :starttime=>params[:starttime] )
    occurrence.to_full_json
  end

  delete '/occurrences/:id' do
    occurrence = ClassOccurrence[params[:id]] or halt 404
    halt 409 unless occurrence.reservations.count == 0
    occurrence.delete
    status 204
  end

  get '/occurrences/:id/details' do
    content_type :json
    id = Integer(params[:id])        rescue halt(404, "ID must be numeric")
    occurrence = ClassOccurrence[id]     or halt(404, "Occurrence Doesn't Exist")
    occurrence.schedule_details_hash.to_json
  end

  get '/occurrences/:id/reservations' do
    content_type :json
    id = Integer(params[:id])        rescue halt(404, "ID must be numeric")
    occurrence = ClassOccurrence[id]     or halt(404, "Occurrence Doesn't Exist")
    occurrence.reservation_list.to_json
  end

  get '/occurrences/:id/frequent_fliers' do
    content_type :json
    id = Integer(params[:id])        rescue halt(404, "ID must be numeric")
    occurrence = ClassOccurrence[id]     or halt(404, "Occurrence Doesn't Exist")
    occurrence.classdef.frequent_flyers.to_json
  end
  
  post '/reservation' do
    custy_id   = Integer(params[:customer_id])   rescue halt(400, "Customer ID Must Be Numeric")
    custy      = Customer[ custy_id ]                or halt(404, "Customer Doesn't Exist")
    
    occurrence = ClassOccurrence.get(params[:classdef_id], params[:staff_id], params[:starttime]) 
    !occurrence.nil?                                 or halt(409, "Trouble Getting Class Occurrence")
    !occurrence.full?                                or halt(409, "Class is Full")
    !occurrence.has_reservation_for? custy_id        or halt(409, "This Person is Already Checked In") 

    message = "#{custy.name} Registered for #{ClassDef[params[:classdef_id]].name} with #{Staff[params[:staff_id]].name} on #{params[:starttime]}"    
    
    !params[:transaction_type].nil?                  or halt(400, "Transaction Type Must Be Specified")

    case params[:transaction_type]
    when "class_pass"
      custy.use_class_pass(message) { occurrence.make_reservation( params[:customer_id] ) } or halt 400
    when "membership"
      custy.use_membership(message) { occurrence.make_reservation( params[:customer_id] ) } or halt 400
    when "payment"
      reservation = occurrence.make_reservation( params[:customer_id] ) or halt 400
      CustomerPayment[params[:payment_id]].update( :class_reservation_id => reservation.id )
    when "free"
      occurrence.make_reservation( params[:customer_id] ) or halt 400
    end

    status 201
  end

  post '/reservations' do
    custy_id   = Integer(params[:customer_id])   rescue halt(400, "Customer ID Must Be Numeric")
    occ_id     = Integer(params[:occurrence_id]) rescue halt(400, "Occurrence ID Must Be Numeric")
    custy      = Customer[ custy_id ]                or halt(404, "Customer Doesn't Exist")
    occurrence = ClassOccurrence[ occ_id ]           or halt(404, "Occurrence Doesn't Exist")
    !occurrence.full?                                or halt(409, "Class is Full")
    !occurrence.has_reservation_for? custy_id        or halt(409, "This Person is Already Checked In") 
    !params[:transaction_type].nil?                  or halt(400, "Transaction Type Must Be Specified")

    message = "#{custy.name} Registered for #{occurrence.description}"    

    case params[:transaction_type]
    when "class_pass"
      custy.use_class_pass(message) { occurrence.make_reservation( params[:customer_id] ) } or halt(400, "Trouble Using Class Pass" )
    when "membership"
      custy.use_membership(message) { occurrence.make_reservation( params[:customer_id] ) } or halt(400, "Trouble Using Membership" )
    when "payment"
      reservation = occurrence.make_reservation( params[:customer_id] )                     or halt(400, "Trouble Making Reservation" )
      CustomerPayment[params[:payment_id]].update( :class_reservation_id => reservation.id )
    when "free"
      occurrence.make_reservation( params[:customer_id] )                                   or halt(400, "Trouble Making Reservation" )
    end

    status 201
  end

  delete '/reservations/:id' do
    res = ClassReservation[params[:id]] or halt 404
    res.cancel
    status 204
  end

  post '/reservations/:id/checkin' do
    reservation = ClassReservation[params[:id]]
    halt 400 if reservation.nil?
    reservation.check_in
  end

  post '/generate' do
    day = params[:day].nil? ? Date.today : Date.parse(params[:day])
    ClassdefSchedule.get_all_occurrences(day.to_s,(day+1).to_s).each do |occ|
      ClassOccurrence.get( occ[:classdef_id], occ[:instructors][0].id, Time.parse(occ[:starttime].to_s) )
    end
    status 204
  end

  post '/exceptions' do
    excep = ClassException.find_or_create( classdef_id: params[:classdef_id], original_starttime: params[:original_starttime] ) 
    teacher_id = ( params[:teacher_id].to_i == 0 ? nil : params[:teacher_id].to_i )
    excep.update( :teacher_id => teacher_id, :starttime => params[:starttime], :cancelled => params[:cancelled], :hidden => params[:hidden])
  end

  delete '/exceptions/:id' do
    excep = ClassException[params[:id]] or halt(404,'Class Exception Not Found')
    excep.delete
  end

  error do
    Slack.err( 'Class Models Error', env['sinatra.error'] )
    'An Error Occurred.'
  end

end
