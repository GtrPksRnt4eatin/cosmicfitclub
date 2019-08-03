class EventPrice < Sequel::Model

  many_to_one :event
  #many_to_one :sessions, :class => :EventSession
  one_to_many :event_tickets

  def to_token
    { :id => self.id, :title => self.title, :member_price=> self.member_price, :full_price => self.full_price }
  end

end