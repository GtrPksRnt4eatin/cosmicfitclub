class ClassDef < Sequel::Model

  include ImageUploader[:image]

  def after_save
  	self.id
  	super
  end

end

class ClassDefRoutes < Sinatra::Base

  get '/' do
    JSON.generate ClassDef.all.map { |c| { :id => c.id, :name => c.name, :description => c.description, :image_url => c.image_url } }
  end
  
  post '/' do
    ClassDef.create(name: params[:name], description: params[:description], image: params[:image] )
    status 200
  end

  delete '/:id' do
    halt 404 if ClassDef[params[:id]].nil?
    ClassDef[params[:id]].destroy
    status 200
  end

end