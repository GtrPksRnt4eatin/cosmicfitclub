require 'omniauth'
require 'omniauth-facebook'
require 'omniauth-google-oauth2'

module Sinatra

  module Omni

    def self.registered(app)
      
      app.use OmniAuth::Builder do
        configure { |config| config.path_prefix = '/omni' }
        provider :facebook, ENV['FACEBOOK_ID'], ENV['FACEBOOK_SECRET']
        #provider :google_oauth2, ENV['GOOGLE_ID'], ENV['GOOGLE_SECRET'], {access_type: "offline", prompt: "consent", scope: 'userinfo.email, userinfo.profile'}
      end

      app.get '/omni/:provider/callback' do
        auth = request.env['omniauth.auth']

        data = {
          :uid       => auth["uid"],
          :provider  => auth["provider"],
          :email     => auth["info"]["email"],
          :name      => auth["info"]["name"],
          :photo_url => auth["info"]["image"]
        }
  
        omni = Omniaccount.find_or_create( :provider => data[:provider], :provider_id => data[:uid] ) do |obj|
          obj.photo_url = data[:photo_url]
        end

        user = User.find_or_create( :email => data[:email] ) do |obj|
          obj.name = data[:name]
        end

        user.add_omniaccount(omni)
        user.add_role Role[1]

        session[:user] = user

        redirect '/userpage'
      end

      app.get '/omni/test' do
        'TESTING'
      end

      app.get '/omni/:provider/deauthorized' do
        "App Deauthorized"
      end

      app.get 'omni/failure' do
        render_page :omnifailure
      end

    end

  end

end