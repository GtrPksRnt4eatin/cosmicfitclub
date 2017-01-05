require 'sinatra/base'
require_relative './omniauth'

class CFCAuth < Sinatra::Base
  register Sinatra::Omni
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  helpers Sinatra::ViewHelpers
  
  enable :sessions

  set :public_folder, File.dirname(__FILE__)

  get( '/login'    ) { render_page :login    }
  get( '/reset'    ) { render_page :reset    }
  get( '/register' ) { render_page :register }

  post '/login' do
    data = JSON.parse(request.body.read)
    session[:user] = User.authenticate( data['username'], data['password'] )
    halt 401 unless session[:user]
  end

  post '/logout' do
    session[:user] = nil
    redirect '/login'
  end

  post '/register' do
    data = JSON.parse(request.body.read)
    halt 409, 'Username is Already in Use' unless User[:username => data['username'] ].nil?
    halt 409, 'Email is Already in Use' unless User[:email => data['email'] ].nil?
    user = User.create(:name => data['name'], :email => data['email'], :username => data['username'], :password => data['password'], :confirmation => data['confirmation']);
    return 200
  end

  post '/reset' do

  end

  get '/current_user' do
    content_type :json
    user = session[:user]
    halt 404 if user.nil?
    JSON.generate({ :name => user.name, :photo_url => user.photo_url }) 
  end

end

module Sinatra

  module Auth
  
    module Helpers

      def logged_in? ; !session[:user].nil? end

    end
  
    def self.registered(app)

      app.helpers Auth::Helpers

      app.set(:auth) do |role|
        condition do
          redirect '/login' unless logged_in?
          redirect '/' unless session[:user].has_role? role
          true
        end
      end

    end

  end

end
