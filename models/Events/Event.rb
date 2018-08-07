require 'csv'

class Event < Sequel::Model

  plugin :json_serializer

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
    image.nil? ? '' : image[:original].url
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

end