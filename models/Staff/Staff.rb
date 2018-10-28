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

  def Staff::token_list
    Staff.all.map { |x| { :id=>x.id, :name=>x.name } }
  end

  def class_history
    hist_list     = $DB[history_query, id].all
    total_classes = hist_list.count
    avr_headcount = hist_list.inject(0) { |tot,el| tot + el[:count] } / total_classes

    grouped_list  = hist_list.group_by { |x| { :classdef_id => x[:classdef_id], :classdef_name => x[:classdef_name] } }
    grouped_list.map! { |k,v| k.merge(
      { 
      :avr_headcount => v.inject(0) { |tot,el| tot + el[:count] } / v.count,
      :total_classes => v.count,
      :hist_list     => v,
    } ) }

    { :avr_headcount => avr_headcount, 
      :total_classes => total_classes, 
      :hist_list     => hist_list,
      :grouped_list  => grouped_list
    } 
  end

  def mvp_list

  end

end

def mvp_query
  %{

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
    WHERE staff_id = ?
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
end

class StaffRoutes < Sinatra::Base

  get '/' do
    JSON.generate Staff.exclude(:deactivated => true).order(:position).all.map { |s| { :id => s.id, :name => s.name, :title => s.title, :bio => s.bio, :image_url => s.image[:medium].url } }
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
        csv << [ teacher_row[:staff_name].upcase ]
        csv << [ 'DATE', 'CLASSNAME', 'HEADCOUNT', 'PAY' ]
        csv << []
        teacher_row[:class_occurrences].each do |row|
          csv << [ Time.parse(row['starttime']).strftime("%a %m/%d %l:%M %P"), row['class_name'], row['headcount'], row[:pay] ]
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
