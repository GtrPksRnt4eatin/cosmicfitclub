get '/'            do slim :index end

get '*/:file.html' do slim params[:file].to_sym end

get '*/:file.js'   do send_file "js/#{params[:file]}.js"   end
get '*/:file.css'  do send_file "css/#{params[:file]}.css" end

get /.*\.(jpeg|jpg|png|gif|ico|svg)/ do
  return 404 unless File.exist? "img#{request.path}"
  send_file "img#{request.path}"
end

get /.*\.(ttf|woff)/ do
  return 404 unless File.exist? "fonts#{request.path}"
  send_file "fonts#{request.path}"
end