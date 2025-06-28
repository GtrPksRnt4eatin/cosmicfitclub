require 'csv'

class Event < Sequel::Model

  include ImageUploader[:image]

  ###################### ASSOCIATIONS #####################

  one_to_many :tickets,        :class => :EventTicket
  one_to_many :sessions,       :class => :EventSession
  one_to_many :prices,         :class => :EventPrice
  one_to_many :checkins,       :class => :EventCheckin

  one_to_many :collaborations, :class => :EventCollaboration

  many_to_one :wide_image,     :class => :StoredImage
  many_to_one :short_url,      :class => :ShortUrl

  def create_session
    new_session = EventSession.create
    add_session(new_session)
    new_session
  end

  def create_price
    new_price = EventPrice.create
    add_price(new_price)
    new_price
  end

  ###################### ASSOCIATIONS #####################

  ##################### CLASS METHODS #####################

  def Event::customer_history(customer_id)

  end
  
  def Event::duplicate(event_id)
    original = Event[event_id] or return false
    clone = Event.create(original.to_hash.except(:id))
    original.sessions.each do |sess|
      clone.add_session(EventSession.create(sess.to_hash.except(:id)))
    end
    original.prices.each do |price|
      clone.add_price(EventPrice.create(price.to_hash.except(:id)))
    end
    clone
  end

  ##################### CLASS METHODS #####################

  ####################### LIFE CYCLE ######################

  def after_create
    Slack.website_scheduling("Event Created: [\##{self.id}] #{self.name}")
  end

  def after_save
    self.id
    super
  end

  def linked_objects
    objects = []
    objects << "Event Has Sessions" if self.sessions.count > 0
    objects << "Event Has Tickets"  if self.tickets.count > 0
    objects << "Event Has Prices"   if self.prices.count > 0
    objects
  end

  def can_delete?
    return self.linked_objects.count == 0
  end

  def delete
    return false unless self.can_delete?
    super
  end

  ####################### LIFE CYCLE ######################

  #################### ATTRIBUTE ACCESS ###################

  def image_url
    self.image.nil? ? '' : self.image(:original).nil? ? self.image.url : self.image(:original).url
  end

  def get_image(size)
    return nil if self.image.nil?
    return self.image(size) unless self.image(size).nil?
    return self.image
  end

  def thumb_url; thumb_image_url end
  def thumb_image_url
    self.image.nil? ? '' : ( self.image.is_a?(ImageUploader::UploadedFile) ? self.image_url : self.image(:medium).url )
  end

  def wide_image_url
    self.wide_image ? self.wide_image_url : ""
  end

  def multisession?; sessions.count > 1 end
  def sessions
    super.sort
  end

  def tickets
    super.sort{ |x| x.created_on.nil? ? 0 : x.created_on }
  end

  def available_prices
    self.prices.map do |p| 
      next nil if p.hidden
      next nil if DateTime.now > p.available_before       unless p.available_before.nil?
      next nil if DateTime.now < p.available_after        unless p.available_after.nil?
      next nil if p.event_tickets.count >= p.max_quantity unless p.max_quantity.nil?
      next p
    end.compact.sort_by { |x| [ x[:order], x[:id] ] }
  end

  #################### ATTRIBUTE ACCESS ###################

  ################# CALCULATED PROPERTIES #################

  def passes
    self.tickets.map(&:passes).flatten
  end

  def starttime
    return DateTime.now if self.sessions.empty?
    return DateTime.parse(self.sessions.first.start_time)
  end

  def endtime
    return DateTime.now if self.sessions.empty?
    return DateTime.parse(self.sessions.last.end_time)
  end

  def multisession?
    self.sessions.count > 1
  end

  def first_day
    return Date.today if self.sessions.nil?
    min = self.sessions.min_by { |x| x.start_time or '' }
    return Date.today if min.nil?
    Date.parse(min.start_time)
  end

  def last_day
    return Date.parse("2016-01-01") if self.sessions.nil?
    max  = self.sessions.max_by{ |x| x.start_time or '' }
    return Date.parse("2016-01-01") if max.nil?
    Date.parse(max.start_time)
  end

  def headcount
    self.tickets.count
  end

  def daterange
    start  = DateTime.parse(self.sessions.first.start_time)
    finish = DateTime.parse(self.sessions.last.end_time)
    return "#{start.strftime("%a %b %-m %l:%M %p")}-#{finish.strftime("%l:%M %p")}" if start.to_date == finish.to_date
    return "#{start.strftime("%a %b %-m %l:%M %p")}-#{finish.strftime("%a %b %-m %l:%M %p")}" 
  end

  def short_path
    self.short_url ? self.short_url.short_path : ""
  end

  ################# CALCULATED PROPERTIES #################

  ########################## VIEWS ########################
 
  def to_token
    { :id => id,
      :name => name
    }
  end
 
  def list_item
    { :id        => id,
      :name      => name,
      :starttime => starttime,
      :image_url => image_url
    }
  end

  def full_detail
    { :id               => self.id, 
      :name             => self.name,
      :subheading       => self.subheading,
      :poster_lines     => self.poster_lines,
      :description      => self.description,
      :details          => self.details,
      :starttime        => self.starttime.try(:iso8601),
      :endtime          => self.endtime.try(:iso8601),
      :image_url        => self.thumb_image_url,
      :wide_image       => self.wide_image.try(:details_hash),
      :full_image       => self.image_url,
      :short_url        => self.short_url,
      :collaborations   => self.collaborations.map(&:details_view),
      :sessions         => self.sessions,
      :prices           => self.available_prices,
      :a_la_carte       => self.a_la_carte,
      :registration_url => self.registration_url, 
      :mode             => self.mode,
      :hidden           => self.hidden
    }
  end

  def admin_detail
    val = self.full_detail
    val[:prices] = self.prices.sort_by { |x| x[:order] }
    val
  end

  def to_json(options = {})
    val = JSON.parse super
    val['image_url'] = self.image_url
    JSON.generate val
  end

  ########################## VIEWS ########################

  ########################## LISTS ########################

  def Event::future
    list = Event.exclude( hidden: true ).all.select{|x| x.last_day >= Date.today }
    list.sort_by { |x| x.starttime }
  end

  def Event::future_all
    list = Event.all.select{ |x| x.last_day >= Date.today }
    list.sort_by { |x| x.starttime }
  end

  def Event::list_future
    Event::future.map(&:full_detail)
  end

  def Event::list_future_all
    Event::future_all.map(&:full_detail)
  end

  def Event::list_past
    list = Event.all.select{|x| x.last_day < Date.today }
    list.sort_by { |x| x.starttime || x.first_day }.reverse.map(&:full_detail)
  end

  def Event::short_list
    Event.all.sort_by { |x| x.starttime || x.first_day }.reverse.map(&:list_item).to_json
  end

  def Event::next
    Event::future.first
  end

  ########################## LISTS ########################

  ######################## REPORTS ########################

  def attendance
    tickets.map do |tic|
      tic.to_hash.merge( {
        :checkins  => tic.checkins.map(&:to_hash),
        :customer  => tic.customer.try(:to_list_hash),
        :recipient => tic.recipient.try(:to_list_hash),
        :event     => self.to_token,
        :passes    => tic.passes.map(&:to_token)
      } )
    end
  end

  def orphan_tickets
    tics = self.tickets.select { |x| x.passes.length == 0 }
    return nil if tics.length == 0
    { :id          => 0,
      :event_id    => self.id,
      :title       => "Orphan Tickets",
      :passes      => tics.map { |tic| { :ticket => tic.to_token, :customer => tic.customer.to_token } }
    } 
  end

  def attendance2
    (self.sessions.map(&:attendance_hash) << orphan_tickets).compact 
  end

  def accounting_rows
    tickets.sort_by(&:created_on).map(&:accounting_row)
  end

  def accounting_arr
          
      used_payment_ids = []
      totals = { :gross => 0, :fees => 0, :refunds => 0, :net => 0 }

      rows = self.tickets.sort_by{ |x| [ x.try(:created_on), x.try(:id) ] }.map do |tic|

        custy        = tic.recipient.to_list_hash
        custy_info   = [ custy[:id], custy[:name], custy[:email] ]

        if tic.get_stripe_id.nil? then
          payment_info = [ tic.price, 0, 0, tic.price ].map(&:fmt_stripe_money)
          totals.merge!({ :gross => tic.price, :net => tic.price }) { |key, v1, v2| v1 + v2 }
        else
          if used_payment_ids.include?(tic.get_stripe_id) then
            payment_info = [ 0, 0, 0, 0 ].map(&:fmt_stripe_money)
          else
            used_payment_ids << tic.get_stripe_id
            payment      = tic.full_payment_info
            totals.merge!(payment) { |key, v1, v2| v1 + v2 } unless payment.nil?
            payment_info = [ payment[:gross], payment[:fees], payment[:refunds], payment[:net] ].map(&:fmt_stripe_money)
          end
        end
        
        [ tic.id, tic.created_on.strftime("%a %m/%d %I:%M %P") ] + custy_info + payment_info + [ tic.eventprice.try(:title) ]
      
      end
      
      arr = [ [ "Ticket ID", "Purchase Date", "Customer ID", "Name", "Email", "Gross", "Fee", "Refunds", "Net", "Ticket Type" ] ]
      arr + rows << [] << [ "Totals:", "", "", self.headcount, "" ] + totals.values.map(&:fmt_stripe_money)

  end

  def attendance_arr
    arr = []
    val = self.attendance2
    val.each do |x|
      arr << [ "[\##{x[:id]}] #{x[:title].try(:upcase)}" ] #{x[:starttime].strftime("%a %m/%d %I:%M %P")} - #{x[:endtime].strftime("%a %m/%d %I:%M %P")}" ]
      arr << ['','','','','']
      x[:passes].each { |y| arr << [ y[:id], "[\##{y[:ticket][:id]}] #{y[:ticket][:ticketclass].try(:[], :title)}", "[\##{y[:customer][:id]}] #{y[:customer][:name]}", y[:customer][:email], !!y[:checked_in] ? "X" : " " ] }
      arr << ['','','','','']
      arr << ['','','','HEADCOUNT',"#{x[:passes].select{|x| !!x[:checked_in] }.length}/#{x[:passes].length}"]
      arr << ['','','','','']
    end
    arr
  end

  def attendance_csv 
    CSV.generate do |csv| 
      accounting_arr.each { |x| csv << x }
    end
  end

  ######################## REPORTS ########################

  def generate_sheets
    
  end

  #def generate_payroll
  #  proll = Payroll.create({ start_date: self.starttime, end_date: self.endtime})
  #  slip = PayrollSlip.create({ staff_id: row[:staff_id], payroll_id: proll.id})
  #
  #  self.tickets.sort_by{ |x| x.created_on ? x.created_on.to_i : 0 }.each do |tic|
  #      row[:class_occurrences].each do |line|
  #        PayrollLine.create({ 
  #          payroll_slip_id: slip.id,
  #          class_occurrence_id: line[:id],
  #          start_time: line[:starttime],
  #          description: line[:class_name],
  #          quantity: line[:headcount],
  #          category: "class_pay",
  #          value: line[:pay],
  #          cosmic: line[:cosmic],
  #          loft: line[:loft],
  #          loft_rentals: line[:loft_rentals],
  #          loft_classes: line[:loft_classes]
  #        })
  #      end
  #    end
  #    JSON.generate proll
  #  end
  #end

end
