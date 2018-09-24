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

  set :public_folder, File.dirname(__FILE__)

  get( '/login'    ) { render_page :login    }
  get( '/reset'    ) { render_page :reset    }
  get( '/register' ) { render_page :register }
  get( '/activate' ) { render_page :activate }
  get( '/reset'    ) { render_page :activate }

  get '/email_search' do
    content_type :json
    custy = Customer.find_by_email params[:email]
    JSON.generate( custy.nil? ? false : { id: custy.id, email: custy.email, full_name: custy.name} )
  end

  post '/login' do
    data = JSON.parse(request.body.read)
    session[:user] = User.authenticate( data['email'], data['password'] )
    halt 401 unless session[:user]
    session[:customer] = session[:user].customer
    status 204
  end

  post '/logout' do
    session[:user] = nil
    session[:customer] = nil
    redirect '/login'
  end

  post '/register' do
    content_type :json
    data = JSON.parse(request.body.read)
    halt 409, 'Email is Already in Use' unless Customer[:email => data['email'] ].nil?
    customer = Customer.create( :name => data['name'], :email => data['email'] )
    customer.login = User.create
    customer.send_new_account_email
    return JSON.generate({ :id => customer.id })
  end

  post '/register_and_login' do
    content_type :json
    data = JSON.parse(request.body.read)
    halt 409, 'Email is Already in Use' unless Customer[:email => data['email'] ].nil?
    customer = Customer.create( :name => data['name'], :email => data['email'] )
    customer.login = User.create
    customer.send_new_account_email
    session[:user] = customer.login
    session[:customer] = customer
    return JSON.generate({ :id => customer.id })
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
    customer = Customer.find_by_email(data['email'])
    halt 404 if customer.nil?
    customer.reset_password
    status 204
  end

  get '/current_user' do
    content_type :json
    user = session[:user];           halt 404 if user.nil?
    custy = session[:user].customer; halt 404 if custy.nil?
    JSON.generate({ :id => custy.id, :email => custy.email, :name => custy.name }) 
  end

  get '/roles' do
    Role.all.to_json
  end

  get '/roles/:id/list' do
    role = Role[params[:id]] or halt(404, 'Role Not Found')
    users = role.users
    users.map do |usr|
      custy = usr.customer
      next if custy.nil?
      { :user_id => usr.id,
        :customer_id => custy.id,
        :customer_name => custy.name,
        :customer_email => custy.email
      }
    end.to_json
  end

  post '/roles/:id/assign_to/:user_id' do
    role = Role[params[:id]] or halt(404,"Role Not Found")
    usr = User[params[:user_id]] or halt(404,"User Not Found")
    usr.add_role(role)
  end

  post '/roles' do
    Role.create( :name => params[:name] );
  end

  delete '/users/:id/roles/:role_id' do
    usr = User[params[:id]] or halt(404,"User Not Found")
    role = Role[params[:role_id]] or halt(404,"Role Not Found")
    usr.remove_role(role)
  end

  delete '/roles/:id' do
    role = Role[params[:id]] or halt(404,"Role Not Found")
    role.users.count == 0 or halt(402,"Role Must Be Empty First")
    role.delete
  end 

  error do
    Slack.err( 'Auth Error', env['sinatra.error'] )
    'An Error Occurred.'
  end

end

module Sinatra

  module Auth
  
    module Helpers

      def logged_in?       ; !session[:user].nil? end
      def user             ; session[:user]       end
      def customer         ; session[:customer]   end
      def ref_cust         ; session[:user] = User[user[:id]]; session[:customer] = Customer[customer[:id]] end
      
      def has_role?(role)
        session[:user].has_role? role
      end

    end
  
    def self.registered(app)

      app.helpers Auth::Helpers

      app.set(:auth) do |role|
        condition do
          redirect "/auth/login?page=#{request.path}" unless logged_in?
          redirect '/' unless session[:user].has_role? role
          true
        end
      end

    end

  end

end
