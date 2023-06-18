class SlideRoutes < Sinatra::Base

  post '/' do
    Slide.create( image: params[:file], group: 'index' )
    status 200
  end

  get '/' do
    content_type :json
  	JSON.generate Slide.where( :group => 'index' ).all.map { |s| { :id => s.id, :data => JSON.parse(s.image_data), :url => s.image_url, :thumb => s.image_url(:medium) } }
  end

  delete '/:id' do
    halt 404 if Slide[params[:id]].nil?
    Slide[params[:id]].destroy
    status 200
  end

  post '/kids' do
    Slide.create( image: params[:file], group: 'kids' )
    status 200
  end

  get '/kids' do
    JSON.generate Slide.where( :group => 'kids' ).all.map { |s| { :id => s.id, :data => JSON.parse(s.image_data), :url => s.image_url, :thumb => s.image_url(:medium) } }
  end

end
