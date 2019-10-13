require 'csv'

class Staff < Sequel::Model(:staff)

  include PositionAndDeactivate

  plugin :pg_array_associations
  
  many_to_pg_array :schedules, :key => :instructors, :class => :ClassdefSchedule

  one_to_many :hourly_shifts
  one_to_many :class_occurrences
  many_to_one :customer

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

  def Staff::ordered_list
    Staff.exclude(:deactivated => true).order(:position).all.map(&:to_list_hash)
  end

  def Staff::detail_list
    Staff.order_by(:deactivated,:position).map(&:to_details_hash)
  end

  def Staff::desk_staff_list
    Staff.exclude(:deactivated => true).all.select{ |x| x.customer.try(:login).try(:has_role?, 'frontdesk') }.map(&:to_token)
  end

  ############################## LISTS ###############################

  ############################## VIEWS ###############################

  def to_hash
    super.tap { |h| h[:image_data] = JSON.parse(h[:image_data]) unless h[:image_data].nil? }
  end

  def to_token
    { :id=>self.id, :name=>self.name }
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

    SELECT staff_id, staff_name, staff_unpaid, array_to_json(array_agg(row)) AS class_occurrences
    FROM (
      SELECT 
        occurrences.*,
        staff.name AS staff_name,
        staff.unpaid AS staff_unpaid,
        class_defs.name AS class_name,
        (   SELECT COUNT(*) 
            FROM class_reservations
            WHERE class_reservations.class_occurrence_id = occurrences.id
        ) AS headcount
      FROM occurrences
      LEFT JOIN staff ON staff.id = staff_id
      LEFT JOIN class_defs ON class_defs.id = classdef_id
    ) AS row
    GROUP BY staff_id, staff_name, staff_unpaid
  }
end

def Staff::payroll(from, to)
  result = $DB[payroll_query, from, to].all
  result.each { |teacher_row|
    teacher_row[:class_occurrences].reject!  { |x| ClassDef[x['classdef_id'].to_i].unpaid }
    #teacher_row[:class_occurrences].reject!  { |x| x['classdef_id'].to_i == 78  }  # Open Studio
    #teacher_row[:class_occurrences].reject!  { |x| x['classdef_id'].to_i == 123 }  # Tuesday Open Studio 
    teacher_row[:class_occurrences].sort_by! { |x| Time.parse(x['starttime'])   } 
    teacher_row[:class_occurrences].each { |occurrence_row|
      ( occurrence_row[:pay] = 0; next ) if teacher_row['staff_unpaid']
      case occurrence_row['headcount'].to_i
      when 0..1
        20 
      when 2..5
        40
      when 6..10
        60
      when 11..15
        80
      when 16..20
        100
      else
        100
      end
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
  result.sort_by! { |x| Staff[x[:staff_id]].unpaid == true ? 0 : 1 }
  result.each { |x| x[:total_pay] = x[:class_occurrences].inject(0){ |sum,y| sum + y[:pay] } }
  result.reject { |x| x[:class_occurrences].length == 0 }
end