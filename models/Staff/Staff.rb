require 'csv'

class Staff < Sequel::Model(:staff)

  include PositionAndDeactivate

  plugin :pg_array_associations

  many_to_pg_array :schedules, :key => :instructors, :class => :ClassdefSchedule

  one_to_many :hourly_punches
  one_to_many :hourly_shifts
  one_to_many :class_occurrences
  one_to_many :payroll_slips, :class => :PayrollSlip

  many_to_one :customer
  many_to_one :poster_bubble, :class => :StoredImage

  include ImageUploader[:image]

  def after_save
  	self.id
  	super
  end

  ############################## LISTS ##############################

  def Staff::list
    Staff::token_list
  end

  def Staff::token_list
    Staff.all.map(&:to_token)
  end

  def Staff::public_list
    Staff.exclude(:deactivated => true).exclude(:hidden => true).order(:position).all.map(&:to_list_hash)
  end

  def Staff::ordered_list
    Staff.exclude(:deactivated => true).order(:position).all.map(&:to_list_hash)
  end

  def Staff::detail_list
    Staff.order_by(:deactivated,:position).map(&:to_details_hash)
  end

  def Staff::desk_staff_list
    Staff.exclude(:deactivated => true).all.select{ |x| x.customer.try(:login).try(:has_role?, 'frontdesk') }.map(&:to_token)
  end

  def Staff::active_teacher_list
    Staff.all.select { |x| x.schedules.count > 0 }
  end

  ############################## LISTS ###############################

  ############################## VIEWS ###############################

  def footer_lines
    arr = []
    arr << self.name
    list = self.schedules.reject { |x| [133,78].include? x.classdef.id }
    list.each { |x| arr << "#{x.classdef.name.truncate(35)} on #{x.simple_meeting_time_description}" }
    arr
  end

  def to_hash
    super.tap { |h| h[:image_data] = JSON.parse(h[:image_data]) unless h[:image_data].nil? }
  end

  def to_token
    { :id=>self.id, :customer_id=> self.try(:customer).try(:id), :name=>self.name }
  end

  def to_payout_token
    { :id=>self.id, :name=>self.name, :stripe_connect_id=>self.stripe_connect_id }
  end

  def to_list_hash
    { :id=>self.id, :name=>self.name, :title=>self.title, :bio=>self.bio, :image_url=>self.get_image_url(:medium) }
  end

  def to_details_hash
    self.to_hash.merge({
      :image_url    => self.get_image_url(:medium),
      :customer     => self.try(:customer).try(:to_list_hash),
      :subscription => self.try(:customer).try(:subscription).try(:details)   
    }).tap { |hsh| hsh.delete(:image_data) }
  end

  def full_details
    self.to_hash.merge({
      :image_url    => self.get_image_url(:medium),
      :customer     => self.try(:customer).try(:to_list_hash),
      :subscription => self.try(:customer).try(:subscription).try(:details),
      :schedules    => self.schedules.map(&:details_hash),
      :occurrences  => self.class_occurrences.map(&:details_hash),
      :shifts       => self.hourly_shifts.map(&:details_hash)
    })
  end

  ############################## VIEWS ###############################

  ########################### ATTRIBUTES #############################

  def get_image_url(size)
    return '' if self.image.nil?
    return self.image_url if self.image.is_a? ImageUploader::UploadedFile
    return self.image[size].url
  end

  def thumb_url
    self.get_image_url(:small)
  end

  ########################### ATTRIBUTES #############################

  ############################# HELPERS ##############################
  
    def generate_subscription
      return false if self.customer.nil?
      return false unless self.customer.subscription.nil?
      Subscription.create( :customer => self.customer, :plan_id => 10 )
    end

  ############################# HELPERS ##############################

  ############################# REPORTS ##############################

  def class_history
    raw_mvp_list  = $DB[mvp_query, id].all
    hist_list     = $DB[history_query, id].all
    total_classes = hist_list.count
    avr_headcount = hist_list.inject(0) { |tot,el| tot + el[:count] } / total_classes

    grouped_list  = hist_list.group_by { |x| { :classdef_id => x[:classdef_id], :classdef_name => x[:classdef_name] } }
    grouped_list = grouped_list.map { |k,v| k.merge(
      { 
      :avr_headcount => v.inject(0) { |tot,el| tot + el[:count] } / v.count,
      :total_classes => v.count,
      :hist_list     => v,
      :mvp_list      => sort_mvp_list( raw_mvp_list.select { |x| x[:classdef_id] == k[:classdef_id] } )
    } ) }

    { :avr_headcount => avr_headcount, 
      :total_classes => total_classes, 
      :hist_list     => hist_list,
      :mvp_list      => sort_mvp_list( raw_mvp_list ),
      :grouped_list  => grouped_list
    } 
  end

  def sort_mvp_list(list)
    list = list.group_by { |x| { :customer_id => x[:customer_id], :customer_name => x[:customer_name] } }
    list.map { |k,v| k.merge(
      { :count=>v.inject(0) { |mem,el| mem + el[:count] } }
    ) }.sort_by { |x| -x[:count] } 
  end

  ############################# REPORTS ##############################

end

def mvp_query
  %{
    SELECT
      customer_id,
      classdef_id,
      MAX(classdef_name) AS classdef_name,
      MAX(customer_name) AS customer_name,
      COUNT(customer_id)
    FROM
    class_reservations_details
    WHERE staff_id = ? AND classdef_id != 78
    GROUP BY customer_id, classdef_id
    ORDER BY COUNT(customer_id) DESC
  }
end

def history_query
  %{
    SELECT
      class_occurrences.id,
      starttime,
      classdef_id,
      MAX(class_defs.name) AS classdef_name,
      COUNT(class_reservations.id)
    FROM class_occurrences
    LEFT JOIN class_defs ON classdef_id = class_defs.id
    LEFT JOIN class_reservations ON class_occurrence_id = class_occurrences.id
    WHERE staff_id = ? AND classdef_id != 78
    GROUP BY class_occurrences.id
    ORDER BY starttime DESC
  }
end

def payroll_query
  %{ 
    with occurrences AS (
      SELECT * FROM class_occurrences 
      WHERE starttime > date ?
      AND starttime <= date ?
      ORDER BY starttime
    )

    SELECT staff_id, staff_name, paypal_email, staff_unpaid, array_to_json(array_agg(row)) AS class_occurrences
    FROM (
      SELECT 
        occurrences.*,
        staff.paypal_email AS paypal_email,
        staff.stripe_connect_id AS stripe_id,
        staff.name AS staff_name,
        staff.unpaid AS staff_unpaid,
        class_defs.name AS class_name,
        (   SELECT COUNT(*) 
            FROM class_reservations_details
            WHERE class_reservations_details.class_occurrence_id = occurrences.id
        ) AS headcount,
		(   SELECT SUM(payment_amount)
		    FROM class_reservations_details
		    WHERE class_reservations_details.class_occurrence_id = occurrences.id
		) AS payment_total,
	    (   SELECT ABS(SUM(pass_transaction_delta))
		    FROM class_reservations_details
		    WHERE class_reservations_details.class_occurrence_id = occurrences.id
		) AS passes_total,
	    (   SELECT COUNT(membership_use_id)
		    FROM class_reservations_details
		    WHERE class_reservations_details.class_occurrence_id = occurrences.id
		) AS membership_total
      FROM occurrences
      LEFT JOIN staff ON staff.id = staff_id
      LEFT JOIN class_defs ON class_defs.id = classdef_id
    ) AS row
    GROUP BY staff_id, staff_name, staff_unpaid, paypal_email
  }
end

def Staff::payroll(from, to)
  privates = []
  from = ( from.is_a?(String) ? Date.parse(from) : from )
  to = ( to.is_a?(String) ? Date.parse(to) : to )

  result = $DB[payroll_query, from, to.next_day].all
  result.sort_by! { |x| Staff[x[:staff_id]].unpaid == true ? 0 : 1 }
  result.sort_by! { |x| x[:staff_id] == 106 ? 1 : 0 }

  result.each { |teacher_row|
    teacher_row[:class_occurrences].each     { |x| x.transform_keys!(&:to_sym) }
    teacher_row[:class_occurrences].reject!  { |x| ClassDef[x[:classdef_id].to_i].unpaid }
    teacher_row[:class_occurrences].reject!  { |x| x[:classdef_id].to_i == 188 && privates.push(x) }
    teacher_row[:class_occurrences].sort_by! { |x| Time.parse(x[:starttime]) }
    teacher_row[:staff_id]==106 && teacher_row[:class_occurrences].push(*privates)
	    
    teacher_row[:class_occurrences].each     { |occurrence_row|

      occurrence_row[:payment_total] ||= 0
      occurrence_row[:loft_classes]  ||= 0
      occurrence_row[:loft_rentals]  ||= 0
      
      net_income = (occurrence_row[:passes_total].to_i * 1200) + (occurrence_row[:payment_total])
      default_split = (occurrence_row[:passes_total].to_i * 700) + (occurrence_row[:payment_total] * 0.6) 

      case(teacher_row[:staff_id])
        when 18 # Ben 50/50 Loft & Cosmic
          occurrence_row[:pay]          = default_split
          occurrence_row[:cosmic]       = 0.5 * (net_income - default_split)
          occurrence_row[:loft_classes] = 0.5 * (net_income - default_split)
        #when 103 # Sam Defers to Loft
          #occurrence_row[:pay]          = 0
          #occurrence_row[:cosmic]       = 0
          #occurrence_row[:loft_classes] = net_income
        when 29 # Ara gets $75 minimum
	        occurrence_row[:pay]          = default_split < 7500 ? 7500 : default_split
	        occurrence_row[:cosmic]       = net_income - occurrence_row[:pay]
	        occurrence_row[:loft]         = 0
	      when 157 # Mattew Cusick $100
	        occurrence_row[:pay]          = default_split < 10000 ? 10000 : default_split
	        occurrence_row[:cosmic]       = net_income - occurrence_row[:pay]
	        occurrence_row[:loft]         = 0
        when 106 # Cosmic Loft gets 100% of loft rentals
          occurrence_row[:pay]          = 0
          occurrence_row[:cosmic]       = 0
          occurrence_row[:loft_rentals] = net_income
        when 92 # Aryn $100
          occurrence_row[:pay]          = default_split < 10000 ? 10000 : default_split
	        occurrence_row[:cosmic]       = net_income - occurrence_row[:pay]
	        occurrence_row[:loft]         = 0
        else
          occurrence_row[:pay]          = default_split
          occurrence_row[:cosmic]       = net_income - default_split
          occurrence_row[:loft]         = 0
      end
      occurrence_row[:loft] = occurrence_row[:loft_rentals] + occurrence_row[:loft_classes]

    }
  }
  punch_groups = HourlyPunch.where(starttime: from...to).all.group_by {|x| x.customer_id }
  punch_groups.each { |custy_id, punch_group|
    p "Missing Staff: #{Customer[custy_id].to_list_hash}" if Customer[custy_id].staff[0].nil?
    val = { 
      :staff_id => Customer[custy_id].staff[0].try(:id),
      :staff_name => Customer[custy_id].staff[0].try(:name),
      :class_occurrences => 
        punch_group.map { |punch| 
          { :timerange => "#{punch.rounded_start.strftime('%a %m/%d %l:%M %P')} - #{punch.rounded_end.strftime('%l:%M %P')}",
            :starttime => punch.rounded_start,
            :task => "Front Desk",
            :hours => punch.duration,
            :pay => punch.duration.to_f*10.to_f
          }
        }
    }
    existing = result.find { |x| x[:staff_id] == val[:staff_id] }
    existing[:class_occurrences].concat(val[:class_occurrences]) unless existing.nil?
    result << val if existing.nil?
  }
  result.each     { |x| x[:class_occurrences].sort_by! { |y| y[:starttime] } }
  result.each     { |x| x[:total_pay] = x[:class_occurrences].inject(0){ |sum,y| sum + ( y[:pay] ? y[:pay] : 0 ) } }
  result.each     { |x| x[:total_loft] = x[:class_occurrences].inject(0){ |sum,y| sum + ( y[:loft] ? y[:loft] : 0 ) } }
  result.each     { |x| x[:total_loft_classes] = x[:class_occurrences].inject(0){ |sum,y| sum + ( y[:loft_classes] ? y[:loft_classes] : 0 ) } }
  result.each     { |x| x[:total_loft_rentals] = x[:class_occurrences].inject(0){ |sum,y| sum + ( y[:loft_rentals] ? y[:loft_rentals] : 0 ) } }
  result.each     { |x| x[:total_cosmic] = x[:class_occurrences].inject(0){ |sum,y| sum + ( y[:cosmic] ? y[:cosmic] : 0 ) } }
  result.reject   { |x| x[:class_occurrences].length == 0 }
end

def Staff::payouts_csv(from,to)
  from = ( from.is_a?(String) ? Date.parse(from) : from )
  to = ( to.is_a?(String) ? Date.parse(to) : to )

  proll = Staff::payroll(from,to)
  csv = CSV.new("")
  csv << ['Email/Phone','Amount','Currency code','Reference ID (optional)','Note to recipient','Recipient wallet','Social Feed Privacy (optional)','Holler URL (deprecated)','Logo URL (optional)']
  proll.each do |teacher_row|
    total = 0
    teacher_row[:class_occurrences].each { |row| total += row[:pay]/100 }
    next if total == 0
    next if teacher_row[:staff_id] == 106 # Cosmic Loft
    next if teacher_row[:staff_id] == 103 # Sam Sweet
    csv << [teacher_row[:paypal_email],total,'USD','',"#{from.strftime('%Y-%m-%d')} to #{to.strftime('%Y-%m-%d')}",'PayPal','PRIVATE','','http://cosmicfitclub.com/banner.png']  
  end
  csv.rewind
  csv
end

def Staff::payroll_csv(from,to)
  from = ( from.is_a?(String) ? Date.parse(from) : from )
  to = ( to.is_a?(String) ? Date.parse(to) : to )

  proll = Staff::payroll(from,to)
  csv = CSV.new("")
  csv << [ 'Payroll' ]
  csv << [ 'Start Date', from.strftime('%Y-%m-%d') ]
  csv << [ 'End Date', to.strftime('%Y-%m-%d') ]
  csv << []
  grand_totals = { :headcount => 0, :passes => 0, :memberships => 0, :payments => 0, :staff_pay => 0, :cosmic => 0, :loft => 0 }
  proll.each do |teacher_row|
    totals = { :headcount => 0, :passes => 0, :memberships => 0, :payments => 0, :staff_pay => 0, :cosmic => 0, :loft => 0}
    csv << [ teacher_row[:staff_name].upcase, "#{from.strftime('%Y-%m-%d')} to #{to.strftime('%Y-%m-%d')}" ]
    csv << [ 'DATE', 'CLASSNAME', 'HEADCOUNT', 'PASSES', 'MEMBERSHIPS', 'PAYMENTS', 'STAFF PAY', 'COSMIC FIT CLUB', 'COSMIC LOFT', 'TRANSATION ID', 'SENT ON']
    csv << []
    teacher_row[:class_occurrences].each do |row|
      row[:payment_total] ||= 0
      csv << [ Time.parse(row[:starttime]).strftime("%m/%d/%Y"), row[:class_name], row[:headcount], row[:passes_total], row[:membership_total], "$ %.2f" % (row[:payment_total]/100), "$ %.2f" % (row[:pay]/100), "$ %.2f" % (row[:cosmic]/100), "$ %.2f" % (row[:loft]/100), "https://cosmicfitclub.com/frontdesk/class_attendance/#{row[:id]}" ] unless row[:class_name].nil?
      csv << [ row[:timerange], row[:task], row[:hours], row[:pay] ] if row[:class_name].nil?
      totals.merge!( { :headcount => row[:headcount], :passes => row[:passes_total], :memberships => row[:membership_total], :payments => row[:payment_total], :staff_pay => row[:pay], :cosmic => row[:cosmic], :loft => row[:loft] } ) { |k,v1,v2| v1 + (!!v2 ? v2 : 0) }
    end
    grand_totals.merge!( totals ) { |k,v1,v2| v1 + (!!v2 ? v2 : 0) }
    csv << [ ]
    csv << [ '','TOTALS', totals[:headcount], totals[:passes], totals[:memberships], "$ %.2f" % (totals[:payments]/100), "$ %.2f" % (totals[:staff_pay]/100), "$ %.2f" % (totals[:cosmic]/100), "$ %.2f" % (totals[:loft]/100) ]
    csv << []
  end
  csv << []
  csv << [ '','GRAND TOTALS', grand_totals[:headcount], grand_totals[:passes], grand_totals[:memberships], "$ %.2f" % (grand_totals[:payments]/100), "$ %.2f" % (grand_totals[:staff_pay]/100),  "$ %.2f" % (grand_totals[:cosmic]/100), "$ %.2f" % (grand_totals[:loft]/100)]
  csv.rewind
  csv
end
