class GiftCertificate < Sequel::Model
  
  many_to_one :customer
  many_to_one :payment, :class => :CustomerPayment, :key => :payment_id
  many_to_one :transaction, :class => :PasTransaction, :key => :transaction_id

  def send_to(email)
    
  end

  def redeem(customer_id)
    self.redeemed? == false       or return false 
    custy = Customer[customer_id] or return false
    transaction = custy.add_passes(self.num_passes, "Redeemed Gift Certificate \##{self.code}", "A Gift From #{self.customer.to_list_string}")
    self.update( :redeemed_on=>Time.now, :transaction => transaction )
    return true
  end

  def redeemed?
    !self.redeemed_on.nil?
  end

  def image_tall
    GiftCert::generate_tall(self.id)
  end

  def GiftCertificate::buy(params)
    GiftCertificate.create({
      :code        => GiftCertificate::generate_code,
      :payment_id  => params[:payment_id],
      :customer_id => params[:customer_id],
      :num_passes  => params[:num_passes],
      :from        => params[:from],
      :to          => params[:to],
      :occasion    => params[:occasion]
    })
  end

  def generate_code
    self.update( :code=> GiftCertificate::generate_code )
  end

  def GiftCertificate::generate_code
    rand(36**8).to_s(36)
  end

end