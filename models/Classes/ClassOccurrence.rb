class ClassOccurrence < Sequel::Model

  many_to_one :classdef, :key => :classdef_id, :class => :ClassDef
  many_to_one :teacher, :key => :staff_id, :class => :Staff
  one_to_many :reservations, :class => :ClassReservation
  many_to_many :customers, :join_table => :class_reservations

  def ClassOccurrence.between(from,to)
    ClassOccurrence.where{ starttime < Date.today }.where{ starttime >= from }.where{ starttime < to }.all
  end

  def ClassOccurrence.get_headcount( class_id, staff_id, starttime )
    occ = find( :classdef_id => class_id, :staff_id => staff_id, :starttime => starttime )
    return 0 if occ.nil? 
    occ.reservations.count
  end

  def ClassOccurrence.get( class_id, staff_id, starttime ) 
    occ = find_or_create( :classdef_id => class_id, :staff_id => staff_id, :starttime => starttime )
    occ.update( :free => true ) if ClassDef[class_id].free
    occ
  end

  def ClassOccurrence.get_email_list(from,to,classdef_ids)
    $DB[ClassOccurrence.email_list_query, classdef_ids, from, to].all
  end

  def headcount
    reservations.count
  end

  def full?
    reservations.count >= capacity
  end

  def reservation_list
    $DB[ClassOccurrence.reservation_list_query, self.id].all
  end

  def make_reservation(customer_id)
    return false if full?
    reservation = ClassReservation.create( :customer_id => customer_id )
    add_reservation reservation
  end

  def move_reservations_from(occ_id)
    ClassOccurrence[occ_id].reservations.each do |res|
      res.update( :class_occurrence_id => self.id )
    end
  end

  def to_full_json
    to_json( :include => { :reservations => {}, :classdef =>  { :only => [ :id, :name ] }, :teacher =>  { :only => [ :id, :name ] } } )
  end

  def to_ical_event
    ical          = Icalendar::Event.new 
    ical.dtstart  = starttime
    ical.duration = "P1H"
    ical.summary  = "#{classdef.name} w/ #{teacher.name}"
    ical
  end

  def schedule_details_hash
    { :type        => 'classoccurrence',
      :classdef_id => classdef.id,
      :title       => classdef.name,
      :instructors => [teacher.to_token],
      :capacity    => capacity,
      :day         => Date.strptime(starttime.to_time.iso8601).to_s,
      :starttime   => starttime.to_time,
      :endtime     => starttime.to_time + 3600,
      :headcount   => headcount
    }
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
               CASE WHEN subscription_id = 10::bigint THEN 'employee' ELSE 'membership' END
             ELSE 'free'
        END AS payment_type,   
        "pass_transactions"."id" AS transaction_id,
        "customer_payments"."id" AS payment_id,
        "membership_uses".id AS membership_use_id,
        "membership_uses"."subscription_id" AS subscription_id
      FROM "class_reservations"
      LEFT JOIN "customers" ON ("customers"."id" = "class_reservations"."customer_id")
      LEFT JOIN "customer_payments" ON ("customer_payments"."class_reservation_id" = "class_reservations"."id") 
      LEFT JOIN "membership_uses" ON ("membership_uses"."reservation_id" = "class_reservations"."id")
      LEFT JOIN "pass_transactions" ON ("pass_transactions"."reservation_id" = "class_reservations"."id")
      WHERE ("class_occurrence_id" = ?)
      ORDER BY "class_reservations"."id"
    }
  end

  def ClassOccurrence.email_list_query
    %{
      SELECT
        customers.id AS customer_id, 
        customers.name AS customer_name,
        customers.email AS customer_email,
        count(class_reservations.id) AS num_visits, 
        array_agg(json_build_object( 'reservation_id', class_reservations.id, 'occurrence_id', occ.id, 'starttime', occ.starttime, 'class_name', class_defs.name )) AS visits
      FROM (
        SELECT *
        FROM class_occurrences
        WHERE classdef_id IN ?
        AND starttime >= ?
        AND starttime < ?
      ) AS occ
      JOIN class_defs ON occ.classdef_id = class_defs.id
      JOIN class_reservations on class_reservations.class_occurrence_id = occ.id
      JOIN customers on class_reservations.customer_id = customers.id
      GROUP BY customers.id
      ORDER BY count(class_reservations.id) DESC
    }
  end

end
