class Plan < Sequel::Model
	
  plugin :json_serializer

  def full_price
    term_months * month_price
  end

end

#id
#name
#price
#renewal_price
#family
#term