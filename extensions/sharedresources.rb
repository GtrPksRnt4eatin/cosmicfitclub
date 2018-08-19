require 'sinatra/base'

module Sinatra
  
  module SharedResources

    def self.registered(app)

      app.get '/elements/:file.js' do
        send_file "shared/js/elements/#{params[:file]}.js"
      end

      app.get '*/:file.js' do
      	send_file "shared/js/#{params[:file]}.js"
      end

      app.get '*/:file.css' do
        send_file "shared/css/#{params[:file]}.css"
      end

      #app.get /.*?(?<file>.*)\.(?<ext>jpeg|jpg|png|gif|ico|svg)/ do
      #  send_file "#{$root_folder}/shared/img#{params[:file]}.#{params[:ext]}"
      #end


      app.get /\/(?<path>([^\/]+\/)+)?(?<file>[^\/]+)\.(?<ext>jpeg|jpg|png|gif|ico|svg)/ do
        path_arr = params[:path].nil? ? [] : params[:path].scan(/\/?(\w+)/).flatten 
        p "#{path_arr} #{params[:path]} #{params[:file]} #{params[:ext]}" 
        path = "#{$root_folder}/shared/img/#{params[:file]}.#{params[:ext]}"
        path = "#{$root_folder}/shared/img/#{path_arr.last(2).join('/')}.#{params[:ext]}" unless File.exists? path
        path = "#{$root_folder}/shared/img/#{path_arr.last(3).join('/')}.#{params[:ext]}" unless File.exists? path
        p "#{path} #{File.exists? path}"
        send_file path if File.exists? path
      end

      app.get /.*?(?<file>[^\/]*)\.(?<ext>ttf|woff|woff2)/ do
        path = "shared/fonts/#{params[:file]}.#{params[:ext]}"
        wfpath = "shared/fonts/webfonts/#{params[:file]}.#{params[:ext]}"
        send_file wfpath if File.exists? wfpath
        send_file "shared/fonts/#{params[:file]}.#{params[:ext]}" unless File.exists? wfpath
      end

    end

  end

end 
