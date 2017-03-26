class ClassDef < Sequel::Model

  plugin :json_serializer

  one_to_many :schedules, :class => :ClassdefSchedule

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

end

class ClassdefSchedule < Sequel::Model
  
  plugin :json_serializer

  many_to_one :classdef

end

class ClassDefRoutes < Sinatra::Base

  get '/' do
    JSON.generate ClassDef.order(:position).all.map { |c| { :id => c.id, :name => c.name, :description => c.description, :image_url => c.image[:small].url } }
  end
  
  post '/' do
    ClassDef.create(name: params[:name], description: params[:description], image: params[:image], position: ClassDef.max(:position) + 1)
    status 200
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

end