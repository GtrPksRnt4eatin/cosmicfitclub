require 'sinatra/base'
require_relative './omniauth'
require_relative './models/User'
require_relative './models/Role'
require_relative './models/Omniaccount'

class CFCAuth < Sinatra::Base
  register Sinatra::Omni
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  helpers  Sinatra::ViewHelpers
  
  enable :sessions

  set :public_folder, File.dirname(__FILE__)

  before do
    p request.path_info
  end

  get( '/login'    ) { render_page :login    }
  get( '/reset'    ) { render_page :reset    }
  get( '/register' ) { render_page :register }
  get( '/activate' ) { render_page :activate }
  get( '/reset'    ) { render_page :activate }

  post '/login' do
    data = JSON.parse(request.body.read)
    session[:user] = User.authenticate( data['email'], data['password'] )
    halt 401 unless session[:user]
    session[:customer] = session[:user].customer
    status 204
  end

  post '/logout' do
    session[:user] = nil
    redirect '/login'
  end

  post '/register' do
    data = JSON.parse(request.body.read)
    halt 409, 'Email is Already in Use' unless Customer[:email => data['email'] ].nil?
    customer = Customer.create( :name => data['name'], :email => data['email'] )
    user = User.create( :password => data['password'], :confirmation => data['confirmation'] );
    user.customer = customer
    return 200
  end

  post '/password' do
    halt 400 if params[:password].length < 5
    user = User.find( :reset_token  => params[:token] )
    user.set( :password => params[:password], :confirmation => params[:confirmation], :reset_token => nil ).save
    session[:user] = user
    session[:customer] = session[:user].customer
    redirect '/user'
  end

  post '/reset' do
    data = JSON.parse request.body.read
    customer = Customer.find( :email => data['email'] )
    customer.login.reset_password
  end

  get '/current_user' do
    content_type :json
    user = session[:user]
    halt 404 if user.nil?
    JSON.generate({ :name => user.name, :photo_url => '' }) 
  end

end

module Sinatra

  module Auth
  
    module Helpers

      def logged_in? ; !session[:user].nil? end
      def user       ; session[:user]       end
      def customer   ; session[:customer]   end

    end
  
    def self.registered(app)

      app.helpers Auth::Helpers

      app.set(:auth) do |role|
        condition do
          redirect '/auth/login' unless logged_in?
          redirect '/' unless session[:user].has_role? role
          true
        end
      end

    end

  end

end
