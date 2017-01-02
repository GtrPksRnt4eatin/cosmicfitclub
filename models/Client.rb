class Client < Sequel::Model
  one_through_one :plan, :join_table => :memberships
  one_to_one :membership
end

#id
#first_name
#last_name
#phone
#email