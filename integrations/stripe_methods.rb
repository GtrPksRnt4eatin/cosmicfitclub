require 'stripe'

Stripe.api_key = ENV['STRIPE_SECRET']

module StripeMethods

  ############### Vendor Accounts ############### 

  def StripeMethods::create_new_vendor_account(email)
    account = Stripe::Account.create({
      country: "US",
      email: email,
      controller: {
        fees: { payer: 'application'},
        losses: { payments: 'application'},
        stripe_dashboard: { type: 'express' }
      }
    })
    
    account_link = Stripe::AccountLink.create({
      account: account.id,
      refresh_url: "https://cosmicfitclub.com/stripe/vendor_refresh",
      return_url: "https://cosmicfitclub.com/stripe/vendor_return",
      type: 'account_onboarding'
    })
    
    { id: account.id, onboarding_url: account_link['url'] }
  end

  def StripeMethods::PayoutVendor(amount, connected_acct_id, descriptor="Cosmic Fit Club")
    transfer = Stripe::Transfer.create({ amount: amount, currency:"usd", destination: connected_acct_id, description: descriptor }) unless connected_acct_id=="acct_19PkJECHwAcud5J9"
    payout = Stripe::Payout.create({ amount: amount, currency: "usd", statement_descriptor: descriptor }, {stripe_account: connected_acct_id })
    { transfer: transfer, payout: payout }
  end

  ############### Vendor Accounts ############### 
  def StripeMethods::get_payment_intent(amount,description,custy)
    intent = Stripe::PaymentIntent.create({
      amount: amount,
      description: description,
      currency: 'usd',
      payment_method_types: ['card'],
      customer: custy ? custy.stripe_id : nil,
      receipt_email: custy.email
    })
    { id: intent.id, client_secret: intent.client_secret }.to_json
  end

  def StripeMethods::update_intent(amount,description,intent_id)
    intent = Stripe::PaymentIntent.update(
      intent_id,
      { amount: amount, description: description }
    )
    { id: intent.id, client_secret: intent.client_secret }.to_json 
  end

  def StripeMethods::retreive_intent(intent_id)
    Stripe::PaymentIntent.retrieve(intent_id)
  end

  ############### Manage Payment Sources ###############

  def StripeMethods::create_stripe_customer(customer, card_token)
    id = Stripe::Customer.create(
      :source   => card_token['id'],
      :name     => customer.name,
      :email    => customer.email
    )['id']
    customer.update( :stripe_id => id )
  rescue Exception => e
    Slack.err("Stripe Error", e)
  end

  def StripeMethods::add_card(token_id, customer_id)
    Stripe::Customer.create_source( customer_id, { source: token_id } )
  rescue Exception => e
    Slack.err("Stripe Error", e)
  end

  def StripeMethods::add_card_as_default(token_id, customer_id)
    Stripe::Customer.update( customer_id, { default_source: source_id } )
  rescue Exception => e
    Slack.err("Stripe Error", e)
  end

  def StripeMethods::set_default_card(customer_id, source_id)
    Stripe::Customer.update( customer_id, { default_source: source_id } )
  rescue Exception => e
    Slack.err("Stripe Error", e)
  end

  def StripeMethods::remove_card(customer_id, source_id)
    Stripe::Customer.delete_source( customer_id, source_id )
  rescue Exception => e
    Slack.err("Stripe Error", e)
  end

  ############### Manage Payment Sources ###############

  def StripeMethods::refund(charge_id)
    Stripe::Refund.create( :charge => charge_id )
  rescue Stripe::InvalidRequestError => e
    p e.message
  end

  def StripeMethods::create_customer(token)
    Stripe::Customer.create(
      :source   => token['id'],
      :email    => token['email'],
      :metadata => { :name => token['card']['name'] } 
    )['id']
  end

  def StripeMethods::create_subscription(plan_id, customer_id)
    Stripe::Subscription.create(
      :plan => plan_id,
      :customer => customer_id
    )['id']
  end

  def StripeMethods::buy_pack(pack_id, customer_id) 
    Stripe::Order.create(
      :currency => 'usd',
      :customer => customer_id,
      :items => [ { :type => 'sku', :parent => pack_id } ]
    ).pay( :customer => customer_id )
  end
  
  def StripeMethods::buy_training(quantity, pack_id, customer_id)
    Stripe::Order.create(
      :currency => 'usd',
      :customer => customer_id,
      :items => [ { :type => 'sku', :parent => pack_id, :quantity => quantity } ]
    ).pay( :customer => customer_id )
  end

  def StripeMethods::charge_customer(customer_id, amount, description, metadata)
    Stripe::Charge.create(
      :amount      => amount,
      :currency    => 'usd',
      :customer    => customer_id,
      :description => description,
      :metadata    => metadata
    )
  end

  def StripeMethods::charge_card(token_id, amount, email, description, metadata)
    Stripe::Charge.create(
      :amount        => amount,
      :currency      => 'usd',
      :source        => token_id,
      :receipt_email => email,
      :description   => description, 
      :metadata      => metadata
    )
  end

  def StripeMethods::charge_saved(customer_id, card_id, amount, description, metadata)
    Stripe::Charge.create(
      :amount      => amount,
      :currency    => 'usd',  
      :customer    => customer_id,
      :card        => card_id,
      :description => description,
      :metadata    => metadata
    )
  end

  def StripeMethods::find_customer_by_card(token)
    tok = Stripe::Token.retrieve(token['id'])
    ( p "Couldn't find token"; return nil ) if tok.nil?
    Customer.all.each do |custy|
      next if custy.stripe_id.nil?
      stripe_custy = Stripe::Customer.retrieve(custy.stripe_id)
      next if stripe_custy.nil?
      stripe_custy.sources.each do |source|
        return stripe_custy.id if source.fingerprint == tok.card.fingerprint
      end
    end
    return nil
  end

  def StripeMethods::get_customer(customer_id)
    Stripe::Customer.retrieve({ id: customer_id, expand: ['sources'] })
  end

  def StripeMethods::get_subscription(subscription_id)
    Stripe::Subscription.retrieve(subscription_id)
  end

  def StripeMethods::get_payment_totals(payment_id)
    empty_row = { :gross => 0, :fees => 0, :refunds => 0, :net => 0 }

    return empty_row unless payment_id
     
    charge  = Stripe::Charge.retrieve({id: payment_id, expand: ['refunds']}) rescue nil
    trans   = Stripe::BalanceTransaction.retrieve charge.balance_transaction rescue nil

    return empty_row if trans.nil?

    refunds = charge.refunds.data.map do |refund|
      Stripe::BalanceTransaction.retrieve refund.balance_transaction rescue nil
    end.map(&:net).reduce(0,:+)

    return { :gross => trans.try(:amount), :fees =>  trans.try(:fee), :refunds => refunds, :net => refunds + trans.try(:net),   }
  end

  def StripeMethods::get_transactions(from, to)
    transactions = []
    Stripe::BalanceTransaction.list({ 
      created: { gte: Time.parse(from).to_i, lte: Time.parse(to).to_i }, 
      limit: 100
    }).auto_paging_each do |x|
      payment_type = nil
      alt_description = nil

      if(x.type=="charge" && !!x.source)
        payment = CustomerPayment.find( :stripe_id => x.source)
        payment_type = payment && payment.class_reservation_id ? 'class_payment' : payment_type
        payment_type = payment && payment.tickets.count > 0 ? 'event_ticket' : payment_type
      end

      if(x.type=="transfer" && !!x.source)
        transfer = Stripe::Transfer.retrieve( x.source )
        alt_description = transfer && ( transfer.description || "" ) 
        account = Stripe::Account.retrieve( transfer.destination )
        name = account['business_profile']['name'] if account && account['business_profile']
        (name ||= account['individual']['first_name'] + " " + account['individual']['last_name']) if account && account['individual']
        alt_description += " to #{name}"
      end

      if(x.type=="payout" && !!x.source)
        payout = Stripe::Payout.retrieve( x.source )
        alt_description = payout && payout.statement_descriptor
        alt_description += " to Cosmic Fit Club"
      end
      
      transactions << [
        Time.at(x.created).to_s,
        x.type.to_s,
        payment_type,
        alt_description || x.description.to_s,
        (x.amount / 100.0),
        (x.fee / 100.0),
        (x.net / 100.0),
        x.id.to_s,
        x.source.to_s
      ]
    end

    groups = transactions.group_by { |row| row[1] }
    result = [["Time", "Type", "Payment Type", "Description", "Amount", "Fee", "Net", "ID", "Source"]]
    result << []
    result.concat(groups['charge'].sort_by { |row| Time.parse(row[0]) }) if groups['charge']
    result << []
    result.concat(groups['refund'].sort_by { |row| Time.parse(row[0]) }) if groups['refund']
    result << []
    result.concat(groups['adjustment'].sort_by { |row| Time.parse(row[0]) }) if groups['adjustment']
    result << []
    result.concat(groups['stripe_fee'].sort_by { |row| Time.parse(row[0]) }) if groups['stripe_fee']
    result << []
    result.concat(groups['payment'].sort_by { |row| Time.parse(row[0]) }) if groups['payment']
    result << []
    result.concat(groups['payout'].sort_by { |row| Time.parse(row[0]) }) if groups['payout']
    result.concat(groups['transfer'].sort_by { |row| Time.parse(row[0]) }) if groups['transfer']
    result << []
    result.concat(groups['reserve_transaction'].sort_by { |row| Time.parse(row[0]) }) if groups['reserve_transaction']
    result
  end

  ##########################################################################

  def StripeMethods::generateToken; @token = rand(36**8).to_s(36) end

end
