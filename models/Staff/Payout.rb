class Payout < Sequel::Model(:payouts)

  many_to_one :payroll
  many_to_one :payroll_slip
  many_to_one :staff

  def stripe_connect_id
    return nil unless self.staff && self.staff.stripe_connect_id
    self.staff.stripe_connect_id  
  end

  def stripe_destination
    return nil unless self.stripe_payout_id
    payout = Stripe::Payout.retrieve(self.stripe_payout_id, { stripe_account: stripe_connect_id })
    return payout.destination if payout && payout.destination
    nil
  rescue Stripe::InvalidRequestError
    nil
  end

  def stripe_arrival_date
    return nil unless self.stripe_payout_id
    payout = Stripe::Payout.retrieve(self.stripe_payout_id, { stripe_account: stripe_connect_id })
    return Time.at(payout['arrival_date']) if payout && payout['arrival_date']
    nil
  rescue Stripe::InvalidRequestError
    nil
  end

end