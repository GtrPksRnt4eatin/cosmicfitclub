class Plan < Sequel::Model
  one_through_one :client, :join_table => :subscriptions
	
  plugin :json_serializer

  def full_price;            term_months * month_price    end
  def formatted_full_price;  "$#{ full_price / 100 }.00"  end
  def formatted_month_price; "$#{ month_price / 100 }.00" end

  def subscribe(customer) 
    
  end

end

#id
#name
#price
#renewal_price
#family
#term