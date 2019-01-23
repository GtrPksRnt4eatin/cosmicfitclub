require 'csv'

class Staff < Sequel::Model(:staff)

  include PositionAndDeactivate

  plugin :pg_array_associations
  
  many_to_pg_array :schedules, :key => :instructors, :class => :ClassdefSchedule

  one_to_many :class_occurrences
  many_to_one :customer

  include ImageUploader[:image]

  def after_save
  	self.id
  	super
  end

  def Staff::list
    Staff::token_list
  end

  def Staff::token_list
    Staff.all.map { |x| { :id=>x.id, :name=>x.name } }
  end

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

    SELECT staff_id, staff_name, array_to_json(array_agg(row)) AS class_occurrences
    FROM (
      SELECT 
        occurrences.*,
        staff.name AS staff_name,
        class_defs.name AS class_name,
        (   SELECT COUNT(*) 
            FROM class_reservations
            WHERE class_reservations.class_occurrence_id = occurrences.id
        ) AS headcount
      FROM occurrences
      LEFT JOIN staff ON staff.id = staff_id
      LEFT JOIN class_defs ON class_defs.id = classdef_id
    ) AS row
    GROUP BY staff_id, staff_name
  }
end

def payroll(from, to)
  result = $DB[payroll_query, from, to].all
  result.each { |teacher_row|
    teacher_row[:class_occurrences].reject! { |x| x['classdef_id'].to_i == 78 }
    teacher_row[:class_occurrences].sort_by! { |x| Time.parse(x['starttime']) }
    teacher_row[:class_occurrences].each { |occurrence_row|
      occurrence_row[:pay] = 
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
    val = { :staff_id => Customer[custy_id].staff[0].try(:id),
      :staff_name => Customer[custy_id].staff[0].name,
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
  result
end

class StaffRoutes < Sinatra::Base

  get '/' do
    JSON.generate Staff.exclude(:deactivated => true).order(:position).all.map { |s| { :id => s.id, :name => s.name, :title => s.title, :bio => s.bio, :image_url => s.image.nil? ? "" : s.image[:medium].url } }
  end
  
  post '/' do
  	max = Staff.max(:position)
  	halt 409 unless Staff[:name => params[:name]].nil?
    Staff.create(name: params[:name], title: params[:title], bio: params[:bio], image: params[:image], position: max ? max + 1 : 0 )
    status 200
  end

  delete '/:id' do
    halt 404 if Staff[params[:id]].nil?
    Staff[params[:id]].deactivate
    status 200
  end

  post '/:id/moveup' do
    staff = Staff[params[:id]] or halt 404
    staff.move(true)
  end

  post '/:id/movedn' do
    staff = Staff[params[:id]] or halt 404
    staff.move(false)
  end

  get '/payroll' do
    content_type :json
    JSON.pretty_generate payroll(params[:from],params[:to])
  end

  get '/payroll.csv' do
    content_type 'application/csv'
    attachment "Payroll #{params[:from]}.csv"
    proll = payroll(params[:from],params[:to])
    csv_string = CSV.generate do |csv|
      csv << [ 'Payroll' ]
      csv << [ 'Start Date', params[:from] ]
      csv << [ 'End Date', params[:to] ]
      csv << []
      grand_total = 0
      proll.each do |teacher_row|
        total = 0
        csv << [ teacher_row[:staff_name].upcase, "#{params[:from]} to #{params[:to]}" ]
        csv << [ 'DATE', 'CLASSNAME', 'HEADCOUNT', 'PAY' ]
        csv << []
        teacher_row[:class_occurrences].each do |row|
          csv << [ Time.parse(row['starttime']).strftime("%a %m/%d %l:%M %P"), row['class_name'], row['headcount'], row[:pay] ] unless row['class_name'].nil?
          csv << [ row[:timerange], row[:task], row[:hours], row[:pay] ] if row['class_name'].nil?
          total = total + row[:pay]
        end
        grand_total = grand_total + total
        csv << [ ]
        csv << [ '','', 'TOTAL', "$ #{total}.00" ]
        csv << []
        csv << []
      end
      csv << [ '', '', 'GRAND TOTAL', "$ #{grand_total}.00" ]
    end
  end

end
