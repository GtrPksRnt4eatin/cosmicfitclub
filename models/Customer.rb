class Customer < Sequel::Model
  one_through_one :plan, :join_table => :subscriptions
  one_to_one :subscription
  one_to_one :user

  def exists_in_stripe?
    return false if stripe_id.nil?
    cust = Stripe::Customer.retrieve(stripe_id)
    !cust.nil?
  end

  def create_in_stripe
    
  end

end

#id
#first_name
#last_name
#phone
#email