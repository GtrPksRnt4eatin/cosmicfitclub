require 'stripe'
require 'securerandom'

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
    recipient_name = StripeMethods::get_account_display_name(connected_acct_id)
    payout_description = descriptor.to_s
    payout_description = "#{descriptor} to #{recipient_name}" if recipient_name && !recipient_name.empty?
    transfer = Stripe::Transfer.create({ amount: amount, currency:"usd", destination: connected_acct_id, description: payout_description }) unless connected_acct_id=="acct_19PkJECHwAcud5J9"
    payout = Stripe::Payout.create({ amount: amount, currency: "usd", description: payout_description, statement_descriptor: descriptor }, {stripe_account: connected_acct_id })
    { transfer: transfer, payout: payout }
  end

  def StripeMethods::get_account_display_name(account_id)
    return nil if account_id.nil? || account_id.to_s.empty?
    account = Stripe::Account.retrieve(account_id)
    first_name = StripeMethods::stripe_value(account, 'individual', 'first_name').to_s
    last_name = StripeMethods::stripe_value(account, 'individual', 'last_name').to_s
    full_name = "#{first_name} #{last_name}".gsub(/\s+/, ' ').strip
    return full_name unless full_name.empty?
    company = StripeMethods::stripe_value(account, 'company', 'name').to_s.gsub(/\s+/, ' ').strip
    return company unless company.empty?
    nil
  rescue
    nil
  end

  def StripeMethods::stripe_value(object, *keys)
    value = object
    keys.each do |key|
      return nil if value.nil?
      if value.respond_to?(:[])
        value = value[key] || value[key.to_s] || value[key.to_sym]
      else
        return nil
      end
    end
    value
  end

  ############### Vendor Accounts ############### 
  def StripeMethods::get_payment_intent(amount,description,custy)
    amount = amount.to_i
    if amount == 0
      # $0 charge — create a SetupIntent to save the payment method without charging
      intent = Stripe::SetupIntent.create({
        description: description,
        customer: custy ? custy.stripe_id : nil,
        payment_method_types: ['card']
      })
      return { id: intent.id, client_secret: intent.client_secret, setup_only: true }.to_json
    end
    raise ArgumentError, "Amount #{amount} is below Stripe's minimum charge of 50 cents" if amount < 50
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
    opts = {}
    key = (metadata && (metadata[:client_txn] || metadata['client_txn'] || metadata[:idempotency_key] || metadata['idempotency_key']))
    opts[:idempotency_key] = key if key
    Stripe::Charge.create({
      :amount      => amount,
      :currency    => 'usd',
      :customer    => customer_id,
      :description => description,
      :metadata    => metadata
    }, opts)
  end

  def StripeMethods::charge_card(token_id, amount, email, description, metadata)
    opts = {}
    key = (metadata && (metadata[:client_txn] || metadata['client_txn'] || metadata[:idempotency_key] || metadata['idempotency_key']))
    opts[:idempotency_key] = key if key
    Stripe::Charge.create({
      :amount        => amount,
      :currency      => 'usd',
      :source        => token_id,
      :receipt_email => email,
      :description   => description, 
      :metadata      => metadata
    }, opts)
  end

  def StripeMethods::charge_saved(customer_id, card_id, amount, description, metadata)
    opts = {}
    key = (metadata && (metadata[:client_txn] || metadata['client_txn'] || metadata[:idempotency_key] || metadata['idempotency_key']))
    opts[:idempotency_key] = key if key
    Stripe::Charge.create({
      :amount      => amount,
      :currency    => 'usd',  
      :customer    => customer_id,
      :card        => card_id,
      :description => description,
      :metadata    => metadata
    }, opts)
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

  def StripeMethods::list_balance_transactions(from, to)
    transactions = []
    Stripe::BalanceTransaction.list({
      created: { gte: Time.parse(from).to_i, lte: Time.parse(to).to_i },
      limit: 100
    }).auto_paging_each do |x|
      payment_type = nil
      if x.type.to_s == 'charge' && x.source
        payment_type = StripeMethods::payment_type_for_charge(x.source, x.description.to_s)
      end

      transactions << {
        created: Time.at(x.created),
        type: x.type.to_s,
        payment_type: payment_type,
        description: x.description.to_s,
        amount_cents: x.amount.to_i,
        fee_cents: x.fee.to_i,
        net_cents: x.net.to_i,
        id: x.id.to_s,
        source: x.source.to_s,
        currency: x.currency.to_s.upcase,
        section: StripeMethods::transaction_section(x.type.to_s, payment_type, x.description.to_s)
      }
    end
    transactions.sort_by { |row| row[:created] }
  end

  def StripeMethods::payment_type_for_charge(source_id, description)
    payment = CustomerPayment.find(:stripe_id => source_id) rescue nil
    return nil if payment.nil?

    if payment.tickets.count > 0
      'event_ticket'
    elsif payment.class_reservation_id
      'class_payment'
    elsif payment.tag && !payment.tag.empty?
      payment.tag
    elsif description =~ /donation/i
      'donation'
    elsif description =~ /hour|package|pass/i
      'package'
    else
      nil
    end
  end

  def StripeMethods::transaction_section(type, payment_type, description)
    return 'Transfers' if type == 'transfer'
    return 'Fees' if type == 'stripe_fee' || description =~ /fee/i

    return 'Class Purchases' if ['class_payment', 'event_ticket'].include?(payment_type)
    return 'Point Rentals' if payment_type.to_s =~ /rental/i || description =~ /rental/i
    return 'Packages' if payment_type.to_s =~ /package/i || description =~ /package|hour|pass/i
    return 'Invoices' if payment_type.to_s =~ /invoice/i || description =~ /invoice/i

    if type == 'charge'
      return 'Class Purchases'
    end

    'Other'
  end

  def StripeMethods::monthly_pnl_report(from, to)
    transactions = StripeMethods::list_balance_transactions(from, to)

    by_type = transactions.group_by { |row| row[:type] }
    amount_for = lambda { |type| (by_type[type] || []).sum { |row| row[:amount_cents] } }

    gross_sales_cents = amount_for.call('charge')
    refunds_cents = amount_for.call('refund')
    disputes_cents = amount_for.call('payment_reversal') + amount_for.call('payment_failure_refund')
    adjustments_cents = amount_for.call('adjustment') + amount_for.call('reserve_transaction')
    payouts_cents = amount_for.call('payout')
    transfers_cents = amount_for.call('transfer')
    fees_cents = transactions.sum { |row| row[:fee_cents] }
    net_cents = transactions.sum { |row| row[:net_cents] }

    {
      from: Date.parse(from),
      to: Date.parse(to),
      summary: {
        gross_sales_cents: gross_sales_cents,
        refunds_cents: refunds_cents,
        disputes_cents: disputes_cents,
        adjustments_cents: adjustments_cents,
        payouts_cents: payouts_cents,
        transfers_cents: transfers_cents,
        fees_cents: fees_cents,
        net_cents: net_cents
      },
      transactions: transactions
    }
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
        
        if(payment)
          if payment.tickets.count > 0
            payment_type = 'event_ticket'
          elsif payment.class_reservation_id
            payment_type = 'class_payment'
          elsif payment.tag && !payment.tag.empty?
            payment_type = payment.tag
          elsif x.description =~ /donation/i
            payment_type = 'donation'
          elsif x.description =~ /hour/i
            payment_type = 'package'
          else
            payment_type = ''
          end
        end
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
        payout_description = payout && (payout.description || payout.statement_descriptor || "")
        alt_description = "#{payout_description} to Cosmic Fit Club".strip
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
