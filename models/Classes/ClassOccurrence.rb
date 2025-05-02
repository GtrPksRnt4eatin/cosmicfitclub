class ClassOccurrence < Sequel::Model

  many_to_one :classdef, :key => :classdef_id, :class => :ClassDef
  many_to_one :location, :key => :location_id, :class => :Location
  many_to_one :teacher, :key => :staff_id, :class => :Staff
  many_to_one :schedule, :key => :classdef_schedule_id, :class => :ClassdefSchedule
  one_to_many :reservations, :class => :ClassReservation
  many_to_many :customers, :join_table => :class_reservations


  ############################ Class Methods ################################

  def ClassOccurrence.past_between(from,to)
    ClassOccurrence.where{ starttime < Date.today }.where{ starttime >= from }.where{ starttime < to }.all
  end

  def ClassOccurrence.all_between(from,to)
    ClassOccurrence.where{ starttime >= from }.where{ starttime < to }.all
  end

  def ClassOccurrence.get_headcount( class_id, staff_id, starttime )
    occ = find( :classdef_id => class_id, :staff_id => staff_id, :starttime => starttime )
    return 0 if occ.nil? 
    occ.reservations.count
  end

  def ClassOccurrence.get( class_id, staff_id, starttime, location_id=nil, classdef_schedule_id=nil) 
    occ = find_or_create( :classdef_id => class_id, :staff_id => staff_id, :starttime => starttime, :location_id => location_id )
    occ.update( :classdef_schedule_id => classdef_schedule_id ) if classdef_schedule_id
    occ.update( :free => true ) if ClassDef[class_id].free
    occ
  end

  def ClassOccurrence.get_email_list(from,to,classdef_ids)
    $DB[ClassOccurrence.email_list_query, classdef_ids, from, to].all
  end

  ############################ Class Methods ################################

  ############################# Model Hooks ################################

  def after_create
    self.update( :capacity => self.classdef.capacity ) unless self.classdef.capacity.nil?
  end

  ############################# Model Hooks ################################

  ############################## Properties ################################

  def headcount
    reservations.count
  end

  def starttime
    super.to_time
  end

  def endtime
    self.starttime.to_time + 3600
  end

  def full?
    reservations.count >= capacity
  end

  def description
    "#{ classdef.try(:name) } with #{ teacher.try(:name) } on #{ starttime.to_time.iso8601 }"
  end

  def next_occurrence_id
    occurrence = $DB[ClassOccurrence.next_query, self.classdef_id, self.staff_id, self.starttime, self.starttime].first
    occurrence.nil? ? nil : occurrence[:id]
  end

  def previous_occurrence_id
    occurrence = $DB[ClassOccurrence.previous_query, self.classdef_id, self.staff_id, self.starttime, self.starttime].first
    occurrence.nil? ? nil : occurrence[:id]
  end

  def schedule
    val = super
    (val = self.schedule = ClassdefSchedule.find_matching_schedule(self)) if val.nil?
    return val
  end

  def instructors
    self.schedule ? self.schedule.teachers.map(&:to_token) : [self.teacher.to_token]
  end

  def thumb_url
    self.try(:schedule).try(:image_url) || classdef.thumbnail_image
  end

  ############################## Properties ################################

  ############################ Reservations ################################

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

  def has_reservation_for?(customer_id)
    reservations.any? { |r| r[:customer_id] == customer_id }
  end

  ############################ Reservations ################################

  ############################# Views ################################

  def to_token 
    { :id => self.id,
      :starttime => self.starttime,
      :classdef => self.classdef.to_token,
      :teacher => self.teacher.to_token
    }
  end

  def to_full_json
    self.to_hash.merge({
      :classdef => self.classdef.to_token,
      :teacher => self.teacher.to_token,
      :reservations => self.reservations.map(&to_hash)
    }).to_json
  end

  def to_ical_event
    ical          = Icalendar::Event.new 
    ical.dtstart  = starttime
    ical.duration = "P1H"
    ical.summary  = self.summary
    ical
  end

  def schedule_details_hash
    { :id          => id,
      :type        => 'classoccurrence',
      :classdef_id => classdef.id,
      :title       => classdef.name,
      :instructors => [teacher.to_token],
      :capacity    => capacity,
      :day         => Date.strptime(starttime.to_time.iso8601).to_s,
      :starttime   => starttime.to_time,
      :endtime     => starttime.to_time + 3600,
      :headcount   => headcount,
      :staff_id    => staff_id,
      :classdef    => classdef.to_token,
      :teacher     => teacher.to_token,
      :location    => self.location.try(:to_token) || self.schedule.try(:location).try(:to_token) || classdef.location.try(:to_token) || { :id=>4, :name=>"Cosmic Fit Club (original)" },
      :next_id     => self.next_occurrence_id,
      :prev_id     => self.previous_occurrence_id,
      :thumb_url   => self.thumb_url,
      :allow_free  => self.schedule.try(:allow_free),
    }
  end

  def details_hash
    self.to_hash.merge({
      :classdef => self.classdef.to_token,
      :teacher => self.teacher.to_token,
      :next_id => self.next_occurrence_id,
      :prev_id => self.previous_occurrence_id
    })
  end

  def set_location
    return if self.location
    self.update( :location => self.schedule.try(:location) || classdef.try(:location) )
  end

  def summary
    "#{classdef.name} w/ #{teacher.name}"
  end

  ############################# Views ################################

  ############################## SQL ################################

  def ClassOccurrence.previous_query
    %{
      SELECT id FROM "class_occurrences" 
        WHERE (
              (classdef_id = ?) 
          AND (staff_id    = ?)
          AND (starttime   < ?)
          AND (extract(isodow from date ?) = extract(isodow from starttime))
        )
      ORDER BY "starttime" DESC LIMIT 1
    }
  end

  def ClassOccurrence.next_query
    %{
      SELECT id FROM "class_occurrences" 
        WHERE (
              (classdef_id = ?) 
          AND (staff_id    = ?)
          AND (starttime   > ?)
          AND (extract(isodow from date ?) = extract(isodow from starttime))
        )
      ORDER BY "starttime" LIMIT 1
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
        ABS("pass_transactions"."delta_f") AS pass_amount,
        "customer_payments"."id" AS payment_id,
        "customer_payments"."amount" AS payment_amount,
        "customer_payments"."type" AS payment_type2,
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

  ############################## SQL ################################

end
