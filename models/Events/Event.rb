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

  #################### ATTRIBUTE ACCESS ###################

  def after_save
    self.id
    super
  end

  def image_url
    self.image.nil? ? '' : self.image[:original].url
  end

  def thumb_image_url
    self.image.nil? ? '' : ( self.image.is_a?(ImageUploader::UploadedFile) ? self.image_url : self.image[:small].url )
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
    self.sessions.max_by(&:start_time).start_time.to_date
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
      :starttime   => self.starttime.try(:iso8601), 
      :image_url   => self.thumb_image_url,
      :sessions    => self.sessions,
      :prices      => self.prices
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
    Event.order(:starttime).exclude( starttime: nil ).all.select{|x| x.last_day >= Date.today }.map(&:full_detail)
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
      
      rows = self.tickets.map do |tic|

        custy        = tic.customer_info
        custy_info   = [ custy[:id], custy[:name], custy[:email] ]

        p "#{used_payment_ids} #{tic.stripe_payment_id} #{used_payment_ids.include?(tic.stripe_payment_id)}"
        if used_payment_ids.include?(tic.stripe_payment_id)
          payment_info = [ 0, 0, 0, 0 ]
        else
          used_payment_ids << tic.stripe_payment_id
          payment      = tic.full_payment_info
          payment_info = [ payment[:gross], payment[:fees], payment[:refunds], payment[:net] ].map(&:fmt_stripe_money)
        end

        totals.merge!(payment) { |key, v1, v2| v1 + v2 }
        
        [ tic.id, tic.created_on.strftime("%a %m/%d %I:%M %P") ] + custy_info + payment_info + [ tic.eventprice.title, tic.recipient.try(:id), tic.recipient.try(:name), tic.recipient.try(:email) ]
      
      end

      csv << [ "Ticket ID", "Purchase Date", "Customer ID", "Name", "Email", "Gross", "Fee", "Refunds", "Net", "Ticket Type", "Recipient ID", "Name", "Email" ]
      rows.sort_by{ |x| x[0].to_i }.each { |r| csv << r }
      csv << []
      csv << [ "Totals:", "", "", self.headcount, "" ] + totals.values.map(&:fmt_stripe_money)
      csv.read
    
    end

  end

  ######################## REPORTS ########################

end