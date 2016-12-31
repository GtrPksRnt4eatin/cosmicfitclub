require 'sinatra/base'

module Sinatra
  
  module SharedResources

    def self.registered(app)
      
      app.get '*/:file.js' do
      	send_file "shared/js/#{params[:file]}.js"
      end

      app.get '*/:file.css' do
        send_file "shared/css/#{params[:file]}.css"
      end
    
      app.get /(?<file>.*)\.(?<ext>jpeg|jpg|png|gif|ico|svg)/ do
        send_file "#{$root_folder}/shared/img#{params[:file]}.#{params[:ext]}"
      end

      app.get /(?<file>[^\/]*)\.(?<ext>ttf|woff)/ do
        path = "shared/fonts/#{params[:file]}.#{params[:ext]}"
        wfpath = "shared/fonts/webfonts/#{params[:file]}.#{params[:ext]}"
        send_file wfpath if File.exists? wfpath
        send_file "shared/fonts/#{params[:file]}.#{params[:ext]}" unless File.exists? wfpath
      end

    end

  end

end 
