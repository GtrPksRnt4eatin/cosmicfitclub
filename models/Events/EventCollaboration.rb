
class EventCollaboration < Sequel::Model
  
  many_to_one :customer
  many_to_one :event

  def phone
    self.customer.try(:phone)
  end

  def stripe_connect_id
    self.customer.try(:staff).try(:stripe_connect_id)
  end

  def details_view
    { id: self.id,
      event_id: self.event_id,
      customer: self.customer.to_list_hash,
      phone: self.phone,
      stripe_connect_id: self.stripe_connect_id,
      percentage: self.percentage.to_f || 0,
      notify: self.notify || false     
    }
  end

end
