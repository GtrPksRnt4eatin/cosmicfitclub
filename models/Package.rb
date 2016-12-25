class Package < Sequel::Model
  
  plugin :json_serializer

  def price;           pass_price * num_passes end
  def formatted_price; "$#{ price / 100 }.00"  end

end