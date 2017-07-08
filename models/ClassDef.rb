require 'ice_cube'

class ClassDef < Sequel::Model

  one_to_many :schedules, :class => :ClassdefSchedule, :key => :classdef_id

  include ImageUploader[:image]

  def after_save
  	self.id
  	super
  end 

  def to_json(options = {})
    val = JSON.parse super
    val['image_url'] = image.nil? ? '' : image[:original].url
    JSON.generate val
  end

  def create_schedule
    new_sched = ClassdefSchedule.create
    add_schedule(new_sched)
    new_sched
  end

  def get_occurences(from, to)
    schedules.map do |sched|
      sched.get_occurences(from,to)
    end.flatten
  end

end

class ClassdefSchedule < Sequel::Model
  
  plugin :pg_array_associations
  pg_array_to_many :teachers, :key => :instructors, :class => :Staff

  many_to_one :classdef, :key => :classdef_id, :class => ClassDef

  def get_occurences(from,to)
    return [] if rrule.nil?
    return [] if start_time.nil?
    IceCube::Schedule.new(start_time) do |sched|
      sched.add_recurrence_rule IceCube::Rule.from_ical(rrule)
    end.occurrences_between(Time.parse(from),Time.parse(to))
  end

end

class ClassOccurrence < Sequel::Model

  many_to_one :classdef, :key => :classdef_id, :class => :ClassDef
  many_to_one :teacher, :key => :staff_id, :class => :Staff
  one_to_many :reservations, :class => :ClassReservation

  def ClassOccurrence.get( class_id, staff_id, starttime ) 
    find_or_create( :classdef_id => class_id, :staff_id => staff_id, :starttime => starttime )
  end

  def to_full_json
    to_json( :include => { :reservations => {}, :classdef =>  { :only => [ :id, :name ] }, :teacher =>  { :only => [ :id, :name ] } } )
  end

  def make_reservation(customer_id)
    reservation = ClassReservation.create( :customer_id => customer_id )
    add_reservation reservation
  end

end

class ClassReservation < Sequel::Model

  many_to_one :customer
  many_to_one :occurrence, :class => :ClassOccurrence, :key => :class_occurrence_id
  one_to_one  :transaction, :class => :PassTransaction, :key => :reservation_id
  one_to_one  :membership_use, :class => :MembershipUse, :key => :reservation_id
  one_to_one  :payment, :class => :CustomerPayment, :key => :class_reservation_id

  def check_in
    self.checked_in = DateTime.now
    self.checked_in_by = session[:customer]
    self.save
  end

  def cancel
    self.transaction.undo    if self.transaction
    self.membership_use.undo if self.membership_use
    self.payment.undo        if self.payment
    self.delete
  end

  def payment_type
    return "class pass" if self.transaction
    if self.membership_use then
      return "employee" if self.membership_use.employee_discount?
      return "membership"
    end
    return "membership" if self.membership_use
    if self.payment then
      return "cash" if self.payment.type == "cash"
      return "card" if self.payment.type == "saved card"
      return "card" if self.payment.type == "new card"
    end
    return ""
  end

end

class ClassException < Sequel::Model  

end

class ClassDefRoutes < Sinatra::Base

  get '/' do
    data = ClassDef.exclude(:decativated=>true).order(:position).all.map do |c| 
      { :id => c.id, 
        :name => c.name, 
        :description => c.description,
        :image_url => (  c.image.nil? ? '' : ( c.image.is_a?(ImageUploader::UploadedFile) ? c.image_url : c.image[:small].url ) ),
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

  post '/:id/moveup' do
    current  = ClassDef[params[:id]]
    currentpos = current.position
    prev = ClassDef.where("position < #{current.position}").reverse_order(:position).first
    prevpos = prev.position
    current.update(:position => prevpos )
    prev.update(:position => currentpos )
    status 200
  end

  post '/:id/movedn' do
    current  = ClassDef[params[:id]]
    currentpos = current.position
    nextclass = ClassDef.where("position > #{current.position}").order(:position).first
    nextpos = nextclass.position
    current.update(:position => nextpos )
    nextclass.update(:position => currentpos )
    status 200
  end

  post '/:id/schedules' do
    data = JSON.parse(request.body.read)
    schedule = ClassDef[params[:id]].create_schedule if data['id'] == 0 
    schedule = ClassdefSchedule[data['id']]      unless data['id'] == 0
    data.delete('id')
    schedule.update(data)
    schedule.to_json
  end 

  delete '/schedules/:id' do
    halt 404 if ClassdefSchedule[params[:id]].nil?
    ClassdefSchedule[params[:id]].destroy
    status 200
  end

  get '/schedule/:start/:end' do
    items = []
    ClassdefSchedule.all.each do |sched|
      sched.get_occurences(params[:start], params[:end]).each do |starttime|
        items << { 
          :day => Date.strptime(starttime.to_time.iso8601).to_s,
          :starttime => sched.start_time,
          :endtime => sched.end_time,
          :title => sched.classdef.name,
          :classdef_id => sched.classdef.id,
          :sched_id => sched.id,
          :instructors => sched.teachers
        }
      end
    end
    items = items.group_by { |x| x[:day] }
    arr = []
    items.each { |k,v| arr << { :day => k, :occurrences => v.sort_by { |x| x[:starttime] } } }
    JSON.generate arr.sort_by { |x| x[:day] }
  end

  get '/occurrences' do
    sheets = ClassOccurrence.reverse(:starttime).all.map do |occ|
      { 
        :id           => occ.id,
        :starttime    => occ.starttime.to_time.iso8601,
        :classdef     => { :id => occ.classdef.id, :name => occ.classdef.name },
        :teacher      => { :id => occ.teacher.id, :name => occ.teacher.name },
        :reservations => occ.reservations.map { |res| { :id => res.id, :customer => { :id => res.customer.id, :name => res.customer.name }, :payment_type => res.payment_type } }
      }
    end
    JSON.generate sheets
  end

  post '/occurrences' do 
    occurrence = ClassOccurrence.get(params['classdef_id'], params['staff_id'], params['starttime'])
    occurrence.to_json( :include => { :reservations => {}, :classdef =>  { :only => [ :id, :name ] }, :teacher =>  { :only => [ :id, :name ] } } )
  end

  get '/occurrence/:id/reservations' do  
  end

  post '/reservation' do
    custy = Customer[ params[:customer_id] ]
    halt 400 if params[:transaction_type].nil? 
    halt 400 if custy.nil?
    occurrence = ClassOccurrence.get(params[:classdef_id], params[:staff_id], params[:starttime])
    message = "#{custy.name} Registered for #{ClassDef[params[:classdef_id]].name} with #{Staff[params[:staff_id]].name} on #{params[:starttime]}"    
    case params[:transaction_type]
    when "class_pass"
      custy.use_class_pass(message) { occurrence.make_reservation( params[:customer_id] ) } or halt 400
    when "membership"
      custy.use_membership(message) { occurrence.make_reservation( params[:customer_id] ) } or halt 400
    when "payment"
      reservation = occurrence.make_reservation( params[:customer_id] ) or halt 400
      CustomerPayment[params[:payment_id]].update( :class_reservation_id => reservation.id )
    end
    status 201
  end

  post '/reservation/:id/checkin' do
    reservation = ClassReservation[params[:id]]
    halt 400 if reservation.nil?
    reservation.check_in
  end

end