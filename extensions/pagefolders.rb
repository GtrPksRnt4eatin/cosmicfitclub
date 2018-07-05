require 'sinatra/base'

module Sinatra
  
  module PageFolders

    module Helpers     
      def render_page(page); p "pages/#{page}/#{page}"; p Pathname.new("pages/#{page}/#{page}").exist?; slim :"pages/#{page}/#{page}" end
    end

    def self.registered(app)

      app.helpers PageFolders::Helpers

      app.set :views, app.root

      app.get '*/:file.css' do
        path = "#{app.root}/pages/#{params[:file]}/#{params[:file]}.css"
        pass unless File.exists? path
        send_file path
      end

      app.get '*/:file.js' do
        path = "#{app.root}/pages/#{params[:file]}/#{params[:file]}.js"
        pass unless File.exists? path
        send_file path
      end

      app.get '*/elements/:file.js' do
        path = "#{app.root}/elements/#{params[:file]}.js"
        pass unless File.exists? path
        send_file path  
      end

    end

  end

end