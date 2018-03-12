class Waiver < Sequel::Model
  many_to_one :customer
end