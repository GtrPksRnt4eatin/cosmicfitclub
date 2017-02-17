class Event < Sequel::Model

  one_to_many :sessions, :class => :EventSession
  one_to_many :prices, :class => :EventPrice
  
  include ImageUploader[:image]

  def after_save
  	self.id
  	super
  end

end

class EventSession < Sequel::Model
  
  many_to_one :event
  one_to_many :prices, :class => :EventPrice

end

class EventPrice < Sequel::Model

  many_to_one :event
  many_to_one :sessions, :class => :EventSession

end

class EventRoutes < Sinatra::Base

  get '/' do
    data = Event.order(:starttime).all.map do |c|
      { :id => c.id, 
        :name => c.name, 
        :description => c.description, 
        :starttime => c.starttime.iso8601, 
        :image_url => (  c.image.nil? ? '' : ( c.image.is_a?(ImageUploader::UploadedFile) ? c.image_url : c.image[:small].url ) ),
        :sessions => c.sessions.to_json,
        :prices => c.prices.to_json
      }
    end
    JSON.generate data
  end
  
  post '/' do
    if Event[params[:id]].nil?
      Event.create(name: params[:name], description: params[:description], :starttime => params[:starttime], image: params[:image] )
    else
      Event[params[:id]].update_fields(params, [ :name, :description, :starttime ])
    end
    status 200
  end

  delete '/:id' do
    halt 404 if Event[params[:id]].nil?
    Event[params[:id]].destroy
    status 200
  end 

end