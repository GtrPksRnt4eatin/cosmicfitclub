class GiftCertificate < Sequel::Model
  
  many_to_one :customer
  many_to_one :payment, :class => :CustomerPayment, :key => :payment_id
  many_to_one :transaction, :class => :PasTransaction, :key => :transaction_id

  def send_to(email)
    
  end

  def redeem(customer_id)

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

  def GiftCertificate::generate_code

  end

end