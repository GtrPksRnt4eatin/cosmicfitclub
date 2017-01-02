class Client < Sequel::Model
  one_through_one :plan, :join_table => :subscriptions
  one_to_one :subscription
end

#id
#first_name
#last_name
#phone
#email