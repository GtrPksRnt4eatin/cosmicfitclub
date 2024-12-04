class NfcTag < Sequel::Model

  many_to_one :customer

  def detail_view
    self.to_hash.merge(customer: customer.to_token)
  end
  
end