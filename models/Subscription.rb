class Subscription < Sequel::Model
  many_to_one :customer
  many_to_one :plan
end

#client_id
#membership_id
#initiation_date
#expiration_date
#auto_renewal