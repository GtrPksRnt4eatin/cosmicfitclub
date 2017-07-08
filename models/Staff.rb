class Staff < Sequel::Model(:staff)

  plugin :json_serializer

  include ImageUploader[:image]

  def after_save
  	self.id
  	super
  end

  def decativate
    self.deactivated = true
    self.save
  end

end

class StaffRoutes < Sinatra::Base

  get '/' do
    JSON.generate Staff.exclude(:deactivated => true).order(:position).all.map { |s| { :id => s.id, :name => s.name, :title => s.title, :bio => s.bio, :image_url => s.image[:medium].url } }
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

  post '/:id/moveup' do
    current  = Staff[params[:id]]
    currentpos = current.position
    prev = Staff.where("position < #{current.position}").reverse_order(:position).first
    prevpos = prev.position
    current.update(:position => prevpos )
    prev.update(:position => currentpos )
    status 200
  end

  post '/:id/movedn' do
    current  = Staff[params[:id]]
    currentpos = current.position
    nextclass = Staff.where("position > #{current.position}").order(:position).first
    nextpos = nextclass.position
    current.update(:position => nextpos )
    nextclass.update(:position => currentpos )
    status 200
  end

end