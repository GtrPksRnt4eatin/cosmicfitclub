class Plan < Sequel::Model
  one_through_one :customer, :join_table => :subscriptions

  def full_price;            term_months * month_price    end
  def formatted_full_price;  "$#{ full_price / 100 }.00"  end
  def formatted_month_price; "$#{ month_price / 100 }.00" end

  def Plan::token_list
  	Plan.all.map { |x| x.tokenize }
  end

  def create_subscription(custy_id)
    Subscription.create( :customer_id => custy_id, :plan => self )
  end

  def tokenize
    { :id=>id, :name=>name }
  end

end