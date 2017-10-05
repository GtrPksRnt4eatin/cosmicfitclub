class ClassOccurrence < Sequel::Model
  
  plugin :json_serializer

  many_to_one :classdef, :key => :classdef_id, :class => :ClassDef
  many_to_one :teacher, :key => :staff_id, :class => :Staff
  one_to_many :reservations, :class => :ClassReservation

  def ClassOccurrence.get( class_id, staff_id, starttime ) 
    find_or_create( :classdef_id => class_id, :staff_id => staff_id, :starttime => starttime )
  end

  def to_full_json
    to_json( :include => { :reservations => {}, :classdef =>  { :only => [ :id, :name ] }, :teacher =>  { :only => [ :id, :name ] } } )
  end

  def make_reservation(customer_id)
    reservation = ClassReservation.create( :customer_id => customer_id )
    add_reservation reservation
  end

  def reservation_list
    $DB[ClassOccurrence.reservation_list_query, self.id].all
  end

  def ClassOccurrence.reservation_list_query
    %{
      SELECT
        "class_reservations"."id" AS id, 
        "class_reservations"."checked_in",
        "class_reservations"."customer_id" AS customer_id, 
        "customers"."name" AS customer_name, 
        "customers"."email" AS customer_email,
        CASE WHEN "pass_transactions"."id" IS NOT NULL THEN 'class pass'
             WHEN "customer_payments"."id" IS NOT NULL THEN 
               CASE WHEN "customer_payments"."type" = 'cash' THEN 'cash' ELSE 'card' END
             WHEN "membership_uses"."id" IS NOT NULL THEN 
               CASE WHEN membership_id = 10::bigint THEN 'employee' ELSE 'membership' END
        END AS payment_type,   
        "pass_transactions"."id" AS transaction_id,
        "customer_payments"."id" AS payment_id,
        "membership_uses".id AS membership_use_id,
        "membership_uses"."membership_id" AS membership_id
      FROM "class_reservations"
      LEFT JOIN "customers" ON ("customers"."id" = "class_reservations"."customer_id")
      LEFT JOIN "customer_payments" ON ("customer_payments"."class_reservation_id" = "class_reservations"."id") 
      LEFT JOIN "membership_uses" ON ("membership_uses"."reservation_id" = "class_reservations"."id")
      LEFT JOIN "pass_transactions" ON ("pass_transactions"."reservation_id" = "class_reservations"."id")
      WHERE ("class_occurrence_id" = ?)
      ORDER BY "class_reservations"."id"
    }
  end

end