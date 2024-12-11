class ClassDefRoutes < Sinatra::Base

  ###################################### CONFIG ###################################################

  register Sinatra::Auth
  use JwtAuth

  configure do
    enable :cross_origin
  end

  before do
    content_type :json
    cache_control :no_store
    origin_ok = ['https://video.cosmicfitclub.com', 'https://localhost:3000'].include? request.env["HTTP_ORIGIN"]
    response.headers['Access-Control-Allow-Origin'] = request.env["HTTP_ORIGIN"] if origin_ok
    response.headers['Access-Control-Allow-Credentials'] = 'true'
  end

  ###################################### CONFIG #####################################################

  ####################################### LISTS #####################################################

  get '/' do
    ClassDef.list_active.map(&:adminpage_view).to_json
  end

  get '/ranked_list' do
    ClassdefSchedule.get_class_page_rankings.map { |x| ClassDef[x].adminpage_view }.to_json
  end

  ####################################### LISTS #####################################################

  ################################## CLASSDEF CRUD ##################################################

  get '/:id' do
    id       = Integer(params[:id]) rescue pass
    classdef = ClassDef[ id ]           or halt(404, "ClassDef Doesn't Exist")
    classdef.to_json
  end

  post '/' do
    if ClassDef[params[:id]].nil?
      classdef = ClassDef.create(name: params[:name], description: params[:description], image: params[:image], position: ClassDef.max(:position) + 1)
    else
      classdef = ClassDef[params[:id]]
      classdef.update_fields(params, [ :name, :description, :location_id ] )
      classdef.update( :image => params[:image] ) unless params[:image].nil?
    end
    classdef.to_json
  end

  delete '/:id' do
    id       = Integer(params[:id]) rescue halt(401, "ID Must Be Numeric" )
    classdef = ClassDef[ id ]           or halt(404, "Class Definition not found.")
    classdef.deactivate                 or halt(403, "Class Couldn't be deactivated")
    {}.to_json
  end

  ################################## CLASSDEF CRUD ##################################################

  ################################# CLASSDEF PROPS ##################################################

  post '/:id/image' do
    cls = ClassDef[params[:id]] or halt(404,'classdef not found')
    cls.update( :image => params[:image] )
    status 204; {}.to_json
  end

  ################################# CLASSDEF PROPS ##################################################

  get '/:id/thumb' do
    classdef = ClassDef[params[:id]] or halt 404
    content_type classdef.thumb(:small).try(:mime_type)
    send_file classdef.thumb(:small).try(:download).try(:path)
  end

  post '/:id/moveup' do
    id       = Integer(params[:id]) rescue halt(401, "ID Must Be Numeric" )
    classdef = ClassDef[ id ]           or halt(404, 'Class Definition not found.')
    classdef.move(true)
    status 200
    {}.to_json
  end

  post '/:id/movedn' do
    id       = Integer(params[:id]) rescue halt(401, "ID Must Be Numeric" )
    classdef = ClassDef[id]             or halt(404, 'Class Definition not found.')
    classdef.move(false)
    status 200
    {}.to_json
  end

  get '/:id/next_occurrences/:count' do
    id       = Integer(params[:id]) rescue halt(401, "ID Must Be Numeric")
    classdef = ClassDef[ id ]           or halt(404, 'Class Definition not found.')
    classdef.get_next_occurrences(params[:count]).to_json
  end

  ###################### SCHEDULES #######################################

  get '/:id/schedules' do
    id   = Integer(params[:id]) rescue halt(401, "ID Must Be Numeric" )
    cdef = ClassDef[params[:id]]    or halt(404, 'Class Definition not found.')
    cdef.schedules.to_json
  end

  post '/:id/schedules' do
    data = JSON.parse(request.body.read)
    id = data['id']
    data.delete('id')
    schedule = ClassDef[params[:id]].create_schedule(data) if id == 0 
    schedule = ClassdefSchedule[id].update(data)       unless id == 0
    Slack.website_scheduling("#{Customer[session[:customer_id]].name} changed the class schedule: \r\n#{schedule.description_line}")
    schedule.to_json
  end 

  get '/schedules/:id' do
    id    = Integer(params[:id])      rescue halt(401, "ID Must Be Numeric" )
    sched = ClassdefSchedule[params[:id]] or halt(404, 'Class Schedule not found.')
    sched.details_hash.to_json
  end

  post '/schedules/:id/image' do
    sched = ClassdefSchedule[params[:id]] or halt(404,'schedule not found')
    sched.image.update( :image => params[:image] ) if sched.image
    sched.update( :image => StoredImage.create( :image => params[:image] ) ) unless sched.image
    status 204; {}.to_json    
  end

  delete '/schedules/:id' do
    id = Integer(params[:id])         rescue halt(401, "ID Must Be Numeric" )
    sched = ClassdefSchedule[params[:id]] or halt(404, "Schedule Not Found" )
    Slack.website_scheduling("#{Customer[session[:customer_id]].name} changed the class schedule: \r\n removed #{sched.description_line} from the schedule")
    sched.destroy
    status 204
    {}.to_json
  end

  ###################### SCHEDULES #######################################
 
  get '/schedule_by_day/:day' do
    day = Time.parse(params[:day])
    ClassdefSchedule.get_all_occurrences(day,day+(3600*24)).to_json
  end 

  get '/:id/schedule' do
    id       = Integer(params[:id]) rescue halt(401, "ID Must Be Numeric")
    classdef = ClassDef[params[:id]]    or halt(404, 'Class Definition not found.')
    from = ( params[:from] or DateTime.now.beginning_of_day.to_time )
    to = ( params[:to] or Time.now.months_since(6) )
    JSON.generate classdef.get_full_occurrences(from, to)
  end

  get '/schedule/:start/:end' do
    items = []
    ClassdefSchedule.all.each do |sched|
      sched.get_occurrences(params[:start], params[:end]).each do |starttime|
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

  post '/generate' do
    day = params[:day].nil? ? Date.today : Date.parse(params[:day])
    ClassdefSchedule.get_all_occurrences_with_exceptions_merged(day.to_s,(day+1).to_s).each do |occ|
      ClassOccurrence.get( occ[:classdef_id], occ[:instructors][0][:id], Time.parse(occ[:starttime].to_s, occ[:location_id]) )
    end
    Calendar::get_day_events(day.to_s).each do |evt|
      case evt[:location]
        when 'Loft-1F-Front (4)'
          ClassOccurrence.get( 173, 106, evt[:start].to_time, 2 )
        when 'Loft-1F-Back (8)'
          ClassOccurrence.get( 178, 106, evt[:start].to_time, 2 )
      end
    end
    status 204
    {}.to_json
  end

  ###################### OCCURRENCES #######################################

  get '/occurrences' do
    day = params[:day].nil? ? Date.today : Date.parse(params[:day])
    sheets = ClassOccurrence.where{ |o| (o.starttime >= day) & (o.starttime < day + 1)}.order(:starttime).all.map do |occ|
      {
        :id           => occ.id,
        :starttime    => occ.starttime.to_time.iso8601,
        :classdef     => occ.classdef.to_token,
        :teacher      => occ.teacher.to_token,
        :reservations => occ.reservation_list,
        :location     => occ.location.try(:to_token)
      }
    end
    JSON.generate sheets
  end   

  post '/occurrences' do
    occurrence = ClassOccurrence.get(params['classdef_id'], params['staff_id'], params['starttime'], params['location_id'], params['classdef_schedule_id'] )
    occurrence.to_full_json
  end

  post '/occurrences/:id' do
    id = Integer(params[:id])        rescue halt(401, "ID Must Be Numeric")
    occurrence = ClassOccurrence[id]     or halt(404, "Occurrence Doesn't Exist")
    occurrence.update( :staff_id=>params[:staff_id], :classdef_id=>params[:classdef_id], :starttime=>params[:starttime], :location_id=>params[:location_id] )
    occurrence.schedule_details_hash.to_json
  end

  delete '/occurrences/:id' do
    id = Integer(params[:id])        rescue halt(401, "ID Must Be Numeric")
    occurrence = ClassOccurrence[id]     or halt(404, "Occurrence Doesn't Exist")
    occurrence.reservations.count == 0   or halt(409, "Occurrence Still Has Reservations!")
    occurrence.delete
    status 204
    {}.to_json
  end

  get '/occurrences/:id/details' do
    id = Integer(params[:id])        rescue halt(404, "ID must be numeric")
    occurrence = ClassOccurrence[id]     or halt(404, "Occurrence Doesn't Exist")
    occurrence.schedule_details_hash.to_json
  end

  get '/occurrences/:id/reservations' do
    id = Integer(params[:id])        rescue halt(404, "ID must be numeric")
    occurrence = ClassOccurrence[id]     or halt(404, "Occurrence Doesn't Exist")
    occurrence.reservation_list.to_json
  end

  get '/occurrences/:id/frequent_flyers' do
    id = Integer(params[:id])        rescue halt(404, "ID must be numeric")
    occurrence = ClassOccurrence[id]     or halt(404, "Occurrence Doesn't Exist")
    occurrence.classdef.frequent_flyers.to_json
  end

  ###################### OCCURRENCES #######################################

  ######################### RESERVATIONS ##########################
  
  post '/reservation' do
    custy_id   = Integer(params[:customer_id])   rescue halt(400, "Customer ID Must Be Numeric")
    custy      = Customer[ custy_id ]                or halt(404, "Customer Doesn't Exist")
    
    occurrence = ClassOccurrence.get(params[:classdef_id], params[:staff_id], params[:starttime], params[:location_id]) 
    !occurrence.nil?                                 or halt(409, "Trouble Getting Class Occurrence")
    !occurrence.full?                                or halt(409, "Class is Full")
    !occurrence.has_reservation_for? custy_id        or halt(409, "This Person is Already Checked In") 

    message = "#{custy.name} Registered for #{ClassDef[params[:classdef_id]].name} with #{Staff[params[:staff_id]].name} on #{params[:starttime]}"    
    reservation = {}

    !params[:transaction_type].nil?                  or halt(400, "Transaction Type Must Be Specified")

    case params[:transaction_type]
    when "class_pass"
      custy.use_class_pass(message, params[:pass_price] || 1) { reservation = occurrence.make_reservation( params[:customer_id] ) } or halt 400
    when "membership"
      custy.use_membership(message) { reservation = occurrence.make_reservation( params[:customer_id] ) } or halt 400
    when "payment"
      reservation = occurrence.make_reservation( params[:customer_id] ) or halt 400
      CustomerPayment[params[:payment_id]].update( :class_reservation_id => reservation.id )
    when "free"
      reservation = occurrence.make_reservation( params[:customer_id] ) or halt 400
    end

    Slack.website_purchases(reservation.summary)
    status 201
    reservation.to_json
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
    reservation = {} 

    case params[:transaction_type]
    when "class_pass"
      custy.use_class_pass(message) { reservation = occurrence.make_reservation( params[:customer_id] ) } or halt(400, "Trouble Using Class Pass" )
    when "membership"
      custy.use_membership(message) { reservation = occurrence.make_reservation( params[:customer_id] ) } or halt(400, "Trouble Using Membership" )
    when "payment"
      reservation = occurrence.make_reservation( params[:customer_id] )                                   or halt(400, "Trouble Making Reservation" )
      CustomerPayment[params[:payment_id]].update( :class_reservation_id => reservation.id )
    when "free"
      reservation = occurrence.make_reservation( params[:customer_id] )                                   or halt(400, "Trouble Making Reservation" )
    end

    Slack.website_purchases(reservation.summary)
    status 201
    reservation.to_json
  end

  post '/reservations/exists' do
    custy_id   = Integer(params[:customer_id])   rescue halt(400, "Customer ID Must Be Numeric")
    custy      = Customer[ custy_id ]                or halt(404, "Customer Doesn't Exist")
    occurrence = ClassOccurrence.get(params[:classdef_id], params[:staff_id], params[:starttime], params[:location_id]) 
    !occurrence.nil?                                 or halt(409, "Trouble Getting Class Occurrence")
    JSON.generate(occurrence.has_reservation_for? custy_id)
  end

  delete '/reservations/:id' do
    res = ClassReservation[params[:id]] or halt 404
    res.cancel(params[:to_passes])
    status 204
    {}.to_json
  end

  post '/reservations/:id/checkin' do
    reservation = ClassReservation[params[:id]]
    halt 400 if reservation.nil?
    reservation.check_in
    reservation.to_json
  end

  ######################### RESERVATIONS ##########################

  ######################### EXCEPTIONS ############################

  post '/exceptions' do
    excep = ClassException.find_or_create( classdef_id: params[:classdef_id], original_starttime: params[:original_starttime] ) 
    teacher_id = ( params[:teacher_id].to_i == 0 ? nil : params[:teacher_id].to_i )
    excep.update( :teacher_id => teacher_id, :starttime => params[:starttime], :endtime => params[:endtime], :cancelled => params[:cancelled], :hidden => params[:hidden])
    Slack.website_scheduling(excep.description)
    excep.to_json
  end

  delete '/exceptions/:id' do
    excep = ClassException[params[:id]] or halt(404,'Class Exception Not Found')
    excep.delete
    {}.to_json
  end

  ######################### EXCEPTIONS ############################

  ########################## LOCATIONS ############################

  get '/locations' do
    Location.all.to_json
  end

  ########################## LOCATIONS ############################

  error do
    Slack.err( 'Class Models Error', env['sinatra.error'] )
    'An Error Occurred.'
  end

end
