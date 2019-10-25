require 'sinatra/base'

module Sinatra
  
  module SharedResources

    def self.registered(app)

      app.get '*/bundledjs/:id' do
        cache_control :public, max_age: 604800
        content_type :js
        params[:file].map do |f|
          File.read("shared/js/#{f}.js")
        end.join('')
      end

      app.get '/elements/:file.js' do
        cache_control :public, max_age: 604800
        send_file "shared/js/elements/#{params[:file]}.js"
      end

      app.get '*/:file.js' do
        cache_control :public, max_age: 604800
      	send_file "shared/js/#{params[:file]}.js"
      end

      app.get '*/:file.css' do
        cache_control :public, max_age: 604800
        send_file "shared/css/#{params[:file]}.css"
      end

      app.get /\/(?<path>([^\/]+\/)+)?(?<file>[^\/]+)\.(?<ext>jpeg|jpg|png|gif|ico|svg)/ do
        cache_control :public, max_age: 604800
        path_arr = params[:path].nil? ? [] : params[:path].scan(/\/?(\w+)/).flatten 
        path = "#{$root_folder}/shared/img/#{params[:file]}.#{params[:ext]}"
        path = "#{$root_folder}/shared/img/#{path_arr.last(2).join('/')}.#{params[:ext]}" unless File.exists? path
        path = "#{$root_folder}/shared/img/#{path_arr.last(3).join('/')}.#{params[:ext]}" unless File.exists? path
        send_file path if File.exists? path
      end

      app.get /.*?(?<file>[^\/]*)\.(?<ext>ttf|woff|woff2)/ do
        cache_control :public, max_age: 604800
        path = "shared/fonts/#{params[:file]}.#{params[:ext]}"
        wfpath = "shared/fonts/webfonts/#{params[:file]}.#{params[:ext]}"
        send_file wfpath if File.exists? wfpath
        send_file "shared/fonts/#{params[:file]}.#{params[:ext]}" unless File.exists? wfpath
      end

    end

  end

end 
