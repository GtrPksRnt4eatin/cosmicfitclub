class GiftCertificate < Sequel::Model
  
  many_to_one :customer
  many_to_one :payment, :class => :CustomerPayment, :key => :payment_id
  many_to_one :transaction, :class => :PasTransaction, :key => :transaction_id
  many_to_one :tall_image, :class => :StoredImage, :key => :tall_image_id

  def send_to(email)
    Mail.gift_certificate( email, { :code => self.code } )
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

  def generate_image
    self.update( :tall_image => StoredImage.create( :image => GiftCert::generate_tall(self.id).to_blob ) )
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
    }).generate_image
  end

  def generate_code
    self.update( :code=> GiftCertificate::generate_code )
  end

  def GiftCertificate::generate_code
    rand(36**8).to_s(36)
  end

  def purchase_description
    "[#{customer.id}] #{customer.name} (#{customer.email}) bought a $#{payment.amount.to_f/100} #{num_passes} class Gift Certificate for #{to} \"#{occasion}\""
  end

end