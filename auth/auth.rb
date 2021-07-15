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
    origin_ok = ['https://video.cosmicfitclub.com', 'https://localhost:3000'].include? request.env["HTTP_ORIGIN"]
    response.headers['Access-Control-Allow-Origin'] = request.env["HTTP_ORIGIN"] if origin_ok
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
    user = User.authenticate( data['email'], data['password'] )
    session[:user_id] = user.id unless user.nil?
    if !user then
      custy = Customer.find_by_email( data['email'] )
      Slack.website_access( "Failed Login: Account Not Found - [#{data['email']}]") if custy.nil?
      Slack.website_access( "Failed Login: #{custy.to_list_string}" )          unless custy.nil?
      halt(401, "Login Failed: Incorrect Credentials" )
    end
    jwt = set_jwt_header(user)
    session[:customer_id] = user.customer.id unless user.customer.nil?
    Slack.website_access( "Successful Login #{ user.customer.to_list_string }" )
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
    jwt = set_jwt_header(user)
    JSON.pretty_generate JWT.decode(jwt,ENV['JWT_SECRET'],true,{ algorithm: 'HS256'})
  end

  post '/logout_jwt' do
    session[:user_id] = nil
    session[:customer_id] = nil
    set_jwt_header(nil)
  end

  get '/test_jwt' do
    jwt = request.cookies['cosmicjwt'] or halt(401)
    JSON.pretty_generate JWT.decode(jwt,ENV['JWT_SECRET'],true,{ algorithm: 'HS256'})
  rescue JWT::DecodeError
    [401, { 'Content-Type' => 'text/plain' }, ['A token must be passed.']]
  rescue JWT::ExpiredSignature
    [403, { 'Content-Type' => 'text/plain' }, ['The token has expired.']]
  rescue JWT::InvalidIssuerError
    [403, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid issuer.']]
  rescue JWT::InvalidIatError
    [403, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid "issued at" time.']]
  end

  def create_jwt(user)
    customer = user.customer
    JWT.encode({
        exp: Time.now.to_i + 120 * 60,
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

  def set_jwt_header(user)
    jwt = user ? create_jwt(user) : ''
    val = "cosmicjwt=#{jwt}; domain=.cosmicfitclub.com; path=/; SameSite=None; secure; HttpOnly"
    response.set_header('Set-Cookie', val)
    jwt
  end

  post '/logout' do
    session[:user_id] = nil
    session[:customer_id] = nil
    set_jwt_header(nil)
    redirect '/login'
  end

  post '/register' do
    content_type :json
    data = JSON.parse(request.body.read)
    halt 409, 'Email is Already in Use' unless Customer[:email => data['email'].downcase ].nil?
    custy = Customer.create( :name => data['name'], :email => data['email'] )
    User.create( :customer => custy )
    return JSON.generate({ :id => custy.id })
  end

  post '/register_and_login' do
    content_type :json
    data = JSON.parse(request.body.read)
    halt 409, 'Email is Already in Use' unless Customer[:email => data['email'].downcase ].nil?
    custy = Customer.create( :name => data['name'], :email => data['email'] )
    custy.login.set_password!(params[:password]) if params[:password]
    #user = User.create(:customer => custy)
    jwt = set_jwt_header(custy.login)
    session[:user_id] = custy.login.id
    session[:customer_id] = custy.id
    return JSON.generate({ :id => custy.id })
  end

  post '/register_and_login_jwt' do
    content_type :json
    halt 409, 'Email is Already in Use' unless Customer[:email => params[:email].downcase].nil?
    custy = Customer.create( :name => params[:name], :email => params[:email] )
    custy.login.set_password!(params[:password])
    jwt = set_jwt_header(custy.login)
    JSON.pretty_generate JWT.decode(jwt,ENV['JWT_SECRET'],true,{ algorithm: 'HS256'})
  end

  post '/password' do
    user = User.find( :reset_token  => params[:token] )   
    Slack.website_access( "Token Posted #{ user.customer.to_list_string } - #{ params[:token] }" )      
    halt(400, "This Reset Token is Invalid or Has Expired")     if user.nil?
    halt(400, "Your Password Must Be at least Five Characters") if params[:password].length < 5
    halt(400, "Your Password Does Not Match The Confirmation")  if params[:password] != params[:confirmation]
    user.set( :password => params[:password], :confirmation => params[:confirmation], :reset_token => nil ).save
    session[:user_id] = user.id
    session[:customer_id] = user.customer.id
    Slack.website_access( "Password Reset #{ user.customer.to_list_string } - #{ params[:token] }" ) 
    jwt = set_jwt_header(user)
    JSON.pretty_generate JWT.decode(jwt,ENV['JWT_SECRET'],true,{ algorithm: 'HS256'})
  end

  post '/reset' do
    data = params
    data = JSON.parse(request.body.read).transform_keys(&:to_sym) unless params[:email]
    custy = Customer.find_by_email(data[:email])
    halt 404 if custy.nil?
    Slack.website_access( "Sending Token #{ custy.to_list_string }" )
    custy.reset_password
    JSON.generate({ :status => 'ok'})
  end

  get '/current_user' do
    content_type :json
    user = User[session[:user_id]]          or halt 404
    custy = Customer[session[:customer_id]] or halt 404
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
      def logged_in?       ; !!session[:user_id]             end
      def user             ; User[session[:user_id]]         end
      def customer         ; Customer[session[:customer_id]] end
      
      def has_role?(role)
        User[session[:user_id]].has_role? role
      end

      def read_jwt
        jwt = request.cookies['cosmicjwt'] or return
        jwt = JWT.decode(jwt,ENV['JWT_SECRET'],true,{ algorithm: 'HS256'})
        custy = Customer[jwt[0]["user"]["customer_id"]] or return
        session[:customer_id] = custy.id
        session[:user_id] = custy.user.id
        jwt
      end

    end
  
    def self.registered(app)

      app.helpers Auth::Helpers

      app.set(:auth) do |role|
        condition do
          redirect "/auth/login?page=#{request.path}" unless logged_in?
          redirect '/' unless User[session[:user_id]].has_role? role
          true
        end
      end

      app.set(:onboard) do |role|
        condition do
          redirect "/auth/onboard?page=#{request.path}" unless logged_in?
          redirect '/' unless User[session[:user_id]].has_role? role
          true
        end
      end

      app.set(:self_or) do |role|
        condition do
          return true if User[session[:user_id]].has_role? role
          halt(401, "Cannot Modify Someone Elses Account!") unless session[:customer_id] == Integer(params[:customer_id])
          true
        end
      end

      app.set(:jwt_logged_in) do |bool|
        condition do
          read_jwt
          true
        rescue JWT::DecodeError
          halt(401, 'A token must be passed.')
        rescue JWT::ExpiredSignature
          halt(403, 'The token has expired.')
        rescue JWT::InvalidIssuerError
          halt(403, 'The token does not have a valid issuer.')
        rescue JWT::InvalidIatError
          halt(403, 'The token does not have a valid "issued at" time.')
        end
      end 

    end

  end

end
