class SlideRoutes < Sinatra::Base

  post '/' do
    Slide.create( image: params[:file], group: 'index' )
    status 200
  end

  get '/' do
  	JSON.generate Slide.where( :group => 'index' ).all.map { |s| { :id => s.id, :data => JSON.parse(s.image_data)['metadata'], :url => s.image[:original].url, :thumb => s.image[:medium].url } }
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
    JSON.generate Slide.where( :group => 'kids' ).all.map { |s| { :id => s.id, :data => JSON.parse(s.image_data)['metadata'], :url => s.image[:original].url, :thumb => s.image[:medium].url } }
  end

end