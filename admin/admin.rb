require 'pry'
require 'sinatra/base'

class CFCAdmin < Sinatra::Base

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources

  set :root, File.dirname(__FILE__)

  get( '/'         ) { render_page :index    }
  get( '/carousel' ) { render_page :carousel }
  get( '/classes'  ) { render_page :classes  }

  post '/slides' do
    Slide.create(image: params[:file])
    status 200
  end

  get '/slides' do
  	JSON.generate Slide.all.map { |s| { :id => s.id, :data => JSON.parse(s.image_data)['metadata'], :url => s.image_url } }
  end

  delete '/slides/:id' do
    halt 404 if Slide[params[:id]].nil?
    Slide[params[:id]].destroy
    status 200
  end

  get '/classdefs' do
    JSON.generate ClassDef.all.map { |c| { :id => c.id, :name => c.name, :description => c.description, :image_url => c.image_url } }
  end
  
  post '/classdefs' do
    ClassDef.create(name: params[:name], description: params[:description], image: params[:image] )
    status 200
  end

  delete '/classdefs/:id' do
    halt 404 if ClassDef[params[:id]].nil?
    ClassDef[params[:id]].destroy
    status 200
  end

end