class Plan < Sequel::Model
  one_through_one :customer, :join_table => :subscriptions
	
  plugin :json_serializer

  def full_price;            term_months * month_price    end
  def formatted_full_price;  "$#{ full_price / 100 }.00"  end
  def formatted_month_price; "$#{ month_price / 100 }.00" end

end