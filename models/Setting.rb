
class Setting < Sequel::Model

	def to_json
      val.to_json
    end

end


class SettingRoutes < Sinatra::Base

  get '/:key' do
  	content_type :json
  	setting = Setting[params[:key]]
  	halt 404 if setting.nil?
  	setting.to_json
  end

  post '/:key' do
  	val = JSON.parse request.body.read
    setting = Setting.find_or_create(:key => params[:key])
    setting.update( :val => { :val => val }.to_json )
    status 201
  end

end