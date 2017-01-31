class TrainingPackage < Sequel::Model
  
  plugin :json_serializer

  def price;           pass_price              end
  def formatted_price; "$#{ price / 100 }.00"  end

end