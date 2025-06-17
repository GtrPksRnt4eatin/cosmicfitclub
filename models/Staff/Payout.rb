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
    return nil unless payout && payout.destination
    account = Stripe::Account.retrieve_external_account( stripe_connect_id, payout.destination )
    return nil unless account
    return "%s %s" % [account[:bank_name], account[:last4]]
  rescue Stripe::InvalidRequestError
    nil
  end

  def stripe_arrival_date
    return nil unless self.stripe_payout_id
    payout = Stripe::Payout.retrieve(self.stripe_payout_id, { stripe_account: stripe_connect_id })
    return Time.at(payout['arrival_date']).utc if payout && payout['arrival_date']
    nil
  rescue Stripe::InvalidRequestError
    nil
  end

end