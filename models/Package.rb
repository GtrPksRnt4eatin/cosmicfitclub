class Package < Sequel::Model
  
  plugin :json_serializer

  def price
  	return 0 if pass_price.nil?
  	return 0 if num_passes.nil?
  	pass_price * num_passes 
  end

  def formatted_price
    "$#{ price / 100 }.00"  
  end

end