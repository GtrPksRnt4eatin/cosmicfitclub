
class EventCollaboration < Sequel::Model
  
  many_to_one :customer
  many_to_one :event

  def details_view
    { id: self.id,
      customer: self.customer.to_list_hash,
      label: self.customer.to_list_string,
      event_id: self.event_id,
      phone: self.customer.phone,
      stripe_connect_id: self.customer.staff[0] ? self.customer.staff[0].stripe_connect_id : '',
      percentage: self.percentage.to_f || 0,
      notify: self.notify || false     
    }
  end

end
