class CompTicket < Sequel::Model

  many_to_one :customer
  many_to_one :pass_transaction

  def before_create
    self.code = generate_code
    super
  end

  def generate_code
    rand(36**8).to_s(36)
  end

  def redeem
    transaction = self.customer.add_passes(1, "First Visit Comp", "")
    self.pass_transaction = transaction
    self.save
  end

end