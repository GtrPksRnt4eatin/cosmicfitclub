require 'koala'

module Facebook
  
  Facebook::API = Koala::Facebook::API.new(ENV['FACEBOOK_PAGE_TOKEN'])

end

