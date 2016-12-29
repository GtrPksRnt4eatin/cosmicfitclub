class Event < Sequel::Model
  
  include ImageUploader[:image]

  def after_save
  	self.id
  	super
  end

end

class EventRoutes < Sinatra::Base

  get '/' do
    JSON.generate Event.all.map { |c| { :id => c.id, :name => c.name, :description => c.description, :starttime => c.starttime, :image_url => c.image_url } }
  end
  
  post '/' do
    Event.create(name: params[:name], description: params[:description], :starttime => params[:starttime], image: params[:image] )
    status 200
  end

  delete '/:id' do
    halt 404 if Event[params[:id]].nil?
    Event[params[:id]].destroy
    status 200
  end

end