require 'sinatra/base'
require_relative './omniauth'

class CFCAuth < Sinatra::Base
  register Sinatra::Omni

  enable :sessions

  post '/logout' do
    session[:user] = nil
    redirect '/login'
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