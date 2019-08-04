require 'csv'

class Event < Sequel::Model
  
  include ImageUploader[:image]

  ###################### ASSOCIATIONS #####################

  one_to_many :tickets,  :class => :EventTicket
  one_to_many :sessions, :class => :EventSession
  one_to_many :prices,   :class => :EventPrice

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

  ##################### CLASS METHODS #####################

  ####################### LIFE CYCLE ######################

  def after_create
    Slack.custom("Event Created: [\##{self.id}] #{self.name}")
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
    self.image.nil? ? '' : self.image[:original].url
  end

  def thumb_image_url
    self.image.nil? ? '' : ( self.image.is_a?(ImageUploader::UploadedFile) ? self.image_url : self.image[:medium].url )
  end

  def sessions
    super.sort
  end

  def tickets
    super.sort{ |x| x.created_on.nil? ? 0 : x.created_on }
  end

  #################### ATTRIBUTE ACCESS ###################

  ################# CALCULATED PROPERTIES #################

  def multisession?
    self.sessions.count > 1
  end

  def last_day
    return Date.today if self.sessions.nil?
    max  = self.sessions.max_by{ |x| x.start_time or '' }
    return Date.today if max.nil?
    max.start_time.to_date
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
    { :id          => self.id, 
      :name        => self.name, 
      :description => self.description,
      :details     => self.details,
      :starttime   => self.starttime.try(:iso8601), 
      :image_url   => self.thumb_image_url,
      :sessions    => self.sessions,
      :prices      => self.prices.reject{ |x| x.hidden }
    }
  end

  def to_json(options = {})
    val = JSON.parse super
    val['image_url'] = image.nil? ? '' : image[:original].url
    JSON.generate val
  end

  ########################## VIEWS ########################

  ########################## LISTS ########################

  def Event::list_future
    Event.order(:starttime).exclude( starttime: nil ).exclude( hidden: true ).all.select{|x| x.last_day >= Date.today }.map(&:full_detail)
  end

  def Event::list_past
    Event.reverse( :starttime ).exclude( starttime: nil ).all.select{|x| x.last_day < Date.today }.map(&:full_detail)
  end

  def Event::short_list
    Event.reverse( :starttime ).all.map(&:list_item).to_json
  end

  ########################## LISTS ########################

  ######################## REPORTS ########################

  def attendance_csv 

    CSV.generate do |csv|

      used_payment_ids = []
      totals = { :gross => 0, :fees => 0, :refunds => 0, :net => 0 }
      
      rows = self.tickets.sort_by{ |x| x.created_on ? x.created_on.to_i : 0 }.map do |tic|

        custy        = tic.customer.to_list_hash
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
        
        [ tic.id, tic.created_on.strftime("%a %m/%d %I:%M %P") ] + custy_info + payment_info + [ tic.eventprice.try(:title), tic.recipient.try(:id), tic.recipient.try(:name), tic.recipient.try(:email) ]
      
      end

      csv << [ "Ticket ID", "Purchase Date", "Customer ID", "Name", "Email", "Gross", "Fee", "Refunds", "Net", "Ticket Type", "Recipient ID", "Name", "Email" ] + sessions.map(&:title)
      rows.each { |r| csv << r }
      csv << []
      csv << [ "Totals:", "", "", self.headcount, "" ] + totals.values.map(&:fmt_stripe_money)
      csv.read
    
    end

  end

  ######################## REPORTS ########################

end