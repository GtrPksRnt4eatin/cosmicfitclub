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
    IceCube::Schedule.new(start_time) do |sched|
      sched.add_recurrence_rule IceCube::Rule.from_ical(rrule) unless rrule.nil?
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

end

class ClassReservation < Sequel::Model

  many_to_one :occurrence, :class => :ClassOccurrence
  one_to_one :transaction, :class => :PassTransaction
  many_to_one :customer

end

class ClassException < Sequel::Model
  
  

end

class ClassDefRoutes < Sinatra::Base

  get '/' do
    data = ClassDef.order(:position).all.map do |c| 
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
    ClassDef[params[:id]].destroy
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
    ClassOccurrence.reverse(:starttime).to_json( 
      :include => {
        :reservations => {},
        :classdef => { :only => [ :id, :name ] },
        :teacher  => { :only => [ :id, :name ] }
      }
    )
  end

  post '/occurrences' do 
    occurrence = ClassOccurrence.get(params['classdef_id'], params['staff_id'], params['starttime'])
    occurrence.to_json( :include => { :reservations => {}, :classdef =>  { :only => [ :id, :name ] }, :teacher =>  { :only => [ :id, :name ] } } )
  end

  get '/occurrence/:id/reservations' do
    
  end

  post '/reservations/' do
    
  end

end