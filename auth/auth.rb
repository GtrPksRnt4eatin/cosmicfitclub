require 'jwt'
require 'json'
require 'sinatra/base'
require 'sinatra/cross_origin'
require 'sinatra/cookies'
require_relative './omniauth'
require_relative './models/User'
require_relative './models/Role'
require_relative './models/Omniaccount'

class CFCAuth < Sinatra::Base

  helpers Sinatra::Cookies

  register Sinatra::Omni
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  helpers  Sinatra::ViewHelpers

  set :public_folder, File.dirname(__FILE__)

  configure do
    enable :cross_origin
  end

  before do
    response.headers['Access-Control-Allow-Origin'] = 'https://video.cosmicfitclub.com'
    response.headers['Access-Control-Allow-Credentials'] = 'true'
  end

  get( '/login'    ) { render_page :login    }
  get( '/onboard'  ) { render_page :onboard  }
  get( '/reset'    ) { render_page :reset    }
  get( '/register' ) { render_page :register }
  get( '/reset'    ) { render_page :activate }
  get( '/activate' ) { 
    @user = User.find( :reset_token => params[:token] )
    if @user then
      render_page :activate
    else
      @err="This Token Is No Longer Valid"
      render_page :error
    end
  }

  get '/email_search' do
    content_type :json
    custy = ( params[:email] == '' ? nil : Customer.find_by_email(params[:email]) )
    JSON.generate( custy.nil? ? false : { id: custy.id, email: custy.email, full_name: custy.name} )
  end

  post '/login' do
    data = JSON.parse(request.body.read)
    session[:user] = User.authenticate( data['email'], data['password'] )
    if !session[:user] then
      custy = Customer.find_by_email( data['email'] )
      Slack.website_access( "Failed Login: Account Not Found - [#{data['email']}]") if custy.nil?
      Slack.website_access( "Failed Login: #{custy.to_list_string}" )          unless custy.nil?
      halt(401, "Login Failed: Incorrect Credentials" )
    end
    session[:customer] = session[:user].customer
    Slack.website_access( "Successful Login #{ session[:customer].to_list_string }" )
    status 204
  end

  post '/login_jwt' do
    content_type :json
    user = User.authenticate( params[:email], params[:password] )
    if !user then
      custy = Customer.find_by_email( params[:email] )
      Slack.website_access( "Failed JWT Login: Account Not Found - [#{params[:email]}]") if custy.nil?
      Slack.website_access( "Failed JWT Login: #{custy.to_list_string}" )            unless custy.nil?
      halt(401, "Login Failed: Incorrect Credentials" )
    end
    Slack.website_access( "Successful JWT Login #{ user.customer.to_list_string }" )
    jwt = create_jwt(user)
    response.set_cookie('cosmicjwt', { value: jwt, secure: true, httponly: true, path: '/', domain: '.cosmicfitclub.com' })
    status(200)
    JSON.pretty_generate JWT.decode(jwt,ENV['JWT_SECRET'],true,{ algorithm: 'HS256'})
  end

  get '/test_jwt' do
    jwt = request.cookies['cosmicjwt'] or halt(401)
    JSON.pretty_generate JWT.decode(jwt,ENV['JWT_SECRET'],true,{ algorithm: 'HS256'})
  end

  def create_jwt(user)
    customer = user.customer
    JWT.encode({
        exp: Time.now.to_i + 60 * 60,
        iat: Time.now.to_i,
        iss: ENV['JWT_ISSUER'],
        scopes: user.roles.map(&:name),
        user: {
          user_id: user.id,
          customer_id: customer.id,
          customer_name: customer.name,
          customer_email: customer.email
        }
      }, 
      ENV['JWT_SECRET'], 
      'HS256' 
    )
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
    custy = Customer.create( :name => data['name'], :email => data['email'] )
    User.create( :customer => custy )
    return JSON.generate({ :id => custy.id })
  end

  post '/register_and_login' do
    content_type :json
    data = JSON.parse(request.body.read)
    halt 409, 'Email is Already in Use' unless Customer[:email => data['email'] ].nil?
    custy = Customer.create( :name => data['name'], :email => data['email'] )
    User.create( :customer => custy)
    session[:user] = custy.login
    session[:customer] = custy
    return JSON.generate({ :id => custy.id })
  end

  post '/register_and_login_jwt' do
    content_type :json
    halt 409, 'Email is Already in Use' unless Customer[:email => params[:email]].nil?
    custy = Customer.create( :name => params[:name], :email => params[:email] )
    user = User.create( :customer => custy )
    user.set_password!(params[:password]) unless params[:password].nil?
    jwt = create_jwt(user)
    response.set_cookie('cosmicjwt', { value: jwt, secure: true, httponly: true, path: '/', domain: '.cosmicfitclub.com' })
    JSON.pretty_generate JWT.decode(jwt,ENV['JWT_SECRET'],true,{ algorithm: 'HS256'})
  end

  post '/password' do
    user = User.find( :reset_token  => params[:token] )         
    halt(400, "This Reset Token is Invalid or Has Expired")     if user.nil?
    halt(400, "Your Password Must Be at least Five Characters") if params[:password].length < 5
    halt(400, "Your Password Does Not Match The Confirmation")  if params[:password] != params[:confirmation]
    user.set( :password => params[:password], :confirmation => params[:confirmation], :reset_token => nil ).save
    session[:user] = user
    session[:customer] = session[:user].customer
    Slack.website_access( "Password Reset #{ session[:customer].to_list_string }" )
    redirect '/user'
  end

  post '/reset' do
    data = params
    data = JSON.parse(request.body.read).transform_keys(&:to_sym) unless params[:email]
    customer = Customer.find_by_email(data[:email])
    halt 404 if customer.nil?
    customer.reset_password
    status 204
  end

  get '/current_user' do
    content_type :json
    user = session[:user]           or halt 404
    custy = session[:user].customer or halt 404
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
    Role.create( :name => params[:name] )
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
    ENV['sinatra.error']
  end

end

module Sinatra

  module Auth
  
    module Helpers

      def logged_in?       ; !!session[:user]     end
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

      app.set(:onboard) do |role|
        condition do
          redirect "/auth/onboard?page=#{request.path}" unless logged_in?
          redirect '/' unless session[:user].has_role? role
          true
        end
      end

      app.set(:self_or) do |role|
        condition do
          return true if session[:user].has_role? role
          halt(401, "Cannot Modify Someone Elses Account!") unless session[:customer].id == Integer(params[:customer_id])
          true
        end
      end

    end

  end

end
