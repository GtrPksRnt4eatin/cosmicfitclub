class Membership < Sequel::Model
  many_to_one :client
  many_to_one :plan
end

#client_id
#membership_id
#initiation_date
#expiration_date
#auto_renewal