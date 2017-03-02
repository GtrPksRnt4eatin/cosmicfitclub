class Event < Sequel::Model

  plugin :json_serializer

  one_to_many :sessions, :class => :EventSession
  one_to_many :prices, :class => :EventPrice
  
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

  def create_session
    new_session = EventSession.create
    add_session(new_session)
    new_session
  end

  def create_price
    new_price = EventPrice.create
    add_price(new_price)
    new_price
  end

end

class EventSession < Sequel::Model

  plugin :json_serializer
  
  many_to_one :event
  one_to_many :prices, :class => :EventPrice

end

class EventPrice < Sequel::Model

  plugin :json_serializer

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
        :sessions => c.sessions,
        :prices => c.prices
      }
    end
    JSON.generate data
  end

  get '/:id' do
    c = Event[params[:id]]
    data = { 
      :id => c.id, 
      :name => c.name, 
      :description => c.description, 
      :starttime => c.starttime.iso8601, 
      :image_url => (  c.image.nil? ? '' : ( c.image.is_a?(ImageUploader::UploadedFile) ? c.image_url : c.image[:small].url ) ),
      :sessions => c.sessions,
      :prices => c.prices
    }
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

  post '/:id/sessions' do
    data = JSON.parse(request.body.read)
    session = Event[params[:id]].create_session if data['id'] == 0 
    session = EventSession[data['id']]          unless data['id'] == 0
    data.delete('id')
    session.update(data)
    session.to_json
  end 

  delete '/sessions/:id' do
    halt 404 if EventSession[params[:id]].nil?
    EventSession[params[:id]].destroy
    status 200
  end

  post '/:id/prices' do
    data = JSON.parse(request.body.read)
    price = Event[params[:id]].create_price     if     data['id'] == 0 
    price = EventPrice[data['id']].update(data) unless data['id'] == 0
    price.to_json
  end 

  delete '/prices/:id' do
    halt 404 if EventPrice[params[:id]].nil?
    EventPrice[params[:id]].destroy
    status 200
  end

  delete '/:id' do
    halt 404 if Event[params[:id]].nil?
    Event[params[:id]].destroy
    status 200
  end 

end