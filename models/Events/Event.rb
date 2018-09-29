require 'csv'

class Event < Sequel::Model

  one_to_many :tickets, :class => :EventTicket
  one_to_many :sessions, :class => :EventSession
  one_to_many :prices, :class => :EventPrice
  
  include ImageUploader[:image]

  def after_save
  	self.id
  	super
  end

  def to_json(options = {})
    val = JSON.parse super
    val['image_url'] = image.nil? ? '' : image[:original].url
    JSON.generate val
  end

  def image_url
    self.image.nil? ? '' : self.image[:original].url
  end

  def thumb_image_url
    self.image.nil? ? '' : ( self.image.is_a?(ImageUploader::UploadedFile) ? self.image_url : self.image[:small].url )
  end

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

  def sessions
    super.sort
  end

  def daterange
    start  = DateTime.parse(self.sessions.first.start_time)
    finish = DateTime.parse(self.sessions.last.end_time)
    return "#{start.strftime("%a %b %-m %l:%M %p")}-#{finish.strftime("%l:%M %p")}" if start.to_date == finish.to_date
    return "#{start.strftime("%a %b %-m %l:%M %p")}-#{finish.strftime("%a %b %-m %l:%M %p")}" 
  end

  def headcount
    self.tickets.count
  end

  def details
    { :id          => self.id, 
      :name        => self.name, 
      :description => self.description, 
      :starttime   => self.starttime.try(:iso8601), 
      :image_url   => self.thumb_image_url,
      :sessions    => self.sessions,
      :prices      => self.prices
    }
  end

  def attendance_csv 
    CSV.generate do |csv|
      csv << [ "ID", "Name", "Email", "Gross", "Fee", "Refunds", "Net" ]
      net = 0
      gross = 0
      fees = 0
      refunds = 0
      self.tickets.each do |tic|
        trans = nil
        if tic.stripe_payment_id then
          charge = Stripe::Charge.retrieve(tic.stripe_payment_id) rescue nil
          trans = Stripe::BalanceTransaction.retrieve charge.balance_transaction rescue nil
          net = net + trans.net unless trans.nil?
          gross = gross + trans.amount unless trans.nil?
          fees = fees + trans.fee unless trans.nil?
          refund = 0
          charge.refunds.data.each do |ref|
            t = Stripe::BalanceTransaction.retrieve ref.balance_transaction rescue nil
            net = net + t.net unless t.nil?
            refund = t.net unless t.nil?
            refunds = refunds + t.net unless t.nil?
          end
        end
        id = tic.customer ? tic.customer.id : 0
        name = tic.customer ? tic.customer.name : ""
        email = tic.customer ? tic.customer.email : ""
        csv << [ id, name, email, "$ 0.00", "$ 0.00", "$0.00", "$ 0.00" ] unless trans
        csv << [ id, name, email, fmt_price(trans.amount), fmt_price(trans.fee), fmt_price(refund), fmt_price( trans.net + refund ) ] if trans
      end 
      csv << []
      csv << [ "Totals:", self.headcount, "", fmt_price(gross), fmt_price(fees), fmt_price(refunds), fmt_price(net) ]
    end
  end

  def Event::list
    Event.order(Sequel.desc(:starttime)).all.to_json( :only => [ :id, :name, :starttime, :image_url ] )
  end

  def Event::list_future
    Event.exclude( starttime: nil ).where{ starttime >= Date.today }.order(:starttime).all.map { |evt| evt.details }
  end

  def Event::list_past
    Event.exclude( starttime: nil ).where{ starttime < Date.today }.order(:starttime).all.map { |evt| evt.details }
  end

end