require 'stripe'
require 'securerandom'

Stripe.api_key = ENV['STRIPE_SECRET']

module StripeMethods

  def StripeMethods::stripe_created_bounds(from, to)
    from_str = from.to_s.strip
    to_str = to.to_s.strip

    from_time = Time.parse(from_str)
    to_time = Time.parse(to_str)

    from_date_only = from_str =~ /^\d{4}-\d{2}-\d{2}$/
    to_date_only = to_str =~ /^\d{4}-\d{2}-\d{2}$/

    from_time = Time.parse("#{from_str} 00:00:00") if from_date_only
    to_time = Time.parse("#{to_str} 00:00:00") if to_date_only

    from_time, to_time = to_time, from_time if to_time < from_time
    to_exclusive = to_date_only ? (to_time + 86_400) : to_time

    { gte: from_time.to_i, lt: to_exclusive.to_i }
  end

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

  def StripeMethods::list_balance_transactions(from, to, options = {})
    include_invoice_recipients = options.fetch(:include_invoice_recipients, true)
    include_transfer_recipients = options.fetch(:include_transfer_recipients, true)
    transactions = []
    Stripe::BalanceTransaction.list({
      created: StripeMethods::stripe_created_bounds(from, to),
      limit: 100
    }).auto_paging_each do |x|
      payment_type = nil
      if x.type.to_s == 'charge' && x.source
        payment_type = StripeMethods::payment_type_for_charge(x.source, x.description.to_s)
      end

      description = x.description.to_s
      description = StripeMethods::invoice_description_with_recipient(description, x.source, payment_type) if include_invoice_recipients
      if include_transfer_recipients && x.type.to_s == 'transfer' && x.source
        begin
          transfer = Stripe::Transfer.retrieve(x.source)
          transfer_description = transfer && (transfer.description || "")
          recipient_name = StripeMethods::get_account_display_name(transfer.destination)
          if recipient_name && !recipient_name.to_s.strip.empty?
            base = transfer_description.to_s.strip.empty? ? description.to_s : transfer_description.to_s
            base = 'Transfer' if base.to_s.strip.empty?
            description = "#{base} to #{recipient_name}".strip
          elsif !transfer_description.to_s.strip.empty?
            description = transfer_description.to_s
          end
        rescue
        end
      end
      if x.type.to_s == 'payout' && x.source
        begin
          payout = Stripe::Payout.retrieve(x.source)
          payout_description = payout && (payout.description || payout.statement_descriptor || "")
          unless payout_description.to_s.strip.empty?
            description = "#{payout_description} to Cosmic Fit Club".strip
          end
        rescue
        end
      end

      transactions << {
        created: Time.at(x.created),
        type: x.type.to_s,
        payment_type: payment_type,
        description: description,
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
      description =~ /point/i ? 'rental' : 'class_payment'  
    elsif payment.tag && !payment.tag.empty?
      payment.tag
    elsif description =~ /donation/i
      'donation'
    elsif description =~ /hour|package|pass|pack/i
      'package'
    else
      nil
    end
  end

  def StripeMethods::charge_recipient_name(source_id)
    return nil if source_id.nil? || source_id.to_s.empty?
    key = source_id.to_s
    @charge_recipient_cache ||= {}
    return @charge_recipient_cache[key] if @charge_recipient_cache.key?(key)

    payment = CustomerPayment.find(:stripe_id => key) rescue nil
    if payment && payment.customer
      name = payment.customer.name.to_s.gsub(/\s+/, ' ').strip
      recipient = name.empty? ? payment.customer.email.to_s.gsub(/\s+/, ' ').strip : name
      @charge_recipient_cache[key] = recipient.empty? ? nil : recipient
      return @charge_recipient_cache[key]
    end

    recipient = nil

    charge = Stripe::Charge.retrieve(key) rescue nil
    if charge
      name = StripeMethods::stripe_value(charge, 'billing_details', 'name').to_s.gsub(/\s+/, ' ').strip
      email = StripeMethods::stripe_value(charge, 'billing_details', 'email').to_s.gsub(/\s+/, ' ').strip
      receipt_email = StripeMethods::stripe_value(charge, 'receipt_email').to_s.gsub(/\s+/, ' ').strip
      recipient = name unless name.empty?
      recipient = email if recipient.nil? || recipient.empty?
      recipient = receipt_email if (recipient.nil? || recipient.empty?) && !receipt_email.empty?

      if recipient.nil? || recipient.empty?
        customer_id = StripeMethods::stripe_value(charge, 'customer').to_s
        if !customer_id.empty?
          stripe_customer = Stripe::Customer.retrieve(customer_id) rescue nil
          customer_name = StripeMethods::stripe_value(stripe_customer, 'name').to_s.gsub(/\s+/, ' ').strip
          customer_email = StripeMethods::stripe_value(stripe_customer, 'email').to_s.gsub(/\s+/, ' ').strip
          recipient = customer_name unless customer_name.empty?
          recipient = customer_email if (recipient.nil? || recipient.empty?) && !customer_email.empty?
        end
      end

      if recipient.nil? || recipient.empty?
        invoice_id = StripeMethods::stripe_value(charge, 'invoice').to_s
        if !invoice_id.empty?
          invoice = Stripe::Invoice.retrieve(invoice_id) rescue nil
          invoice_name = StripeMethods::stripe_value(invoice, 'customer_name').to_s.gsub(/\s+/, ' ').strip
          invoice_email = StripeMethods::stripe_value(invoice, 'customer_email').to_s.gsub(/\s+/, ' ').strip
          recipient = invoice_name unless invoice_name.empty?
          recipient = invoice_email if (recipient.nil? || recipient.empty?) && !invoice_email.empty?
        end
      end
    end

    recipient = recipient.to_s.gsub(/\s+/, ' ').strip
    @charge_recipient_cache[key] = recipient.empty? ? nil : recipient
    @charge_recipient_cache[key]
  rescue
    nil
  end

  def StripeMethods::invoice_description_with_recipient(description, source_id, payment_type=nil)
    text = description.to_s.strip
    is_invoice = payment_type.to_s =~ /invoice/i || text =~ /invoice/i
    return text unless is_invoice

    recipient = StripeMethods::charge_recipient_name(source_id)
    return text if recipient.nil? || recipient.empty?
    return text if text =~ /\bto\s+#{Regexp.escape(recipient)}\s*$/i
    return "Invoice to #{recipient}" if text.empty?

    "#{text} to #{recipient}"
  end

  def StripeMethods::transaction_section(type, payment_type, description)
    return 'Transfers' if type == 'payout'
    return 'Transfers' if type == 'transfer'
    return 'Fees' if type == 'stripe_fee' || description =~ /fee/i

    return 'Event Tickets' if payment_type == 'event_ticket'
    return 'Class Purchases' if payment_type == 'class_payment'
    return 'Point Rentals' if payment_type.to_s =~ /rental/i || description =~ /rental/i
    return 'Packages' if payment_type.to_s =~ /package/i || description =~ /package|hour|pass|pack/i
    return 'Invoices' if payment_type.to_s =~ /invoice/i || description =~ /invoice/i

    if type == 'charge'
      return 'Class Purchases'
    end

    'Other'
  end

  def StripeMethods::monthly_pnl_report(from, to, options = {})
    transactions = StripeMethods::list_balance_transactions(from, to, options)

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

  def StripeMethods::transfer_recipient_from_description(description)
    text = description.to_s.strip
    parts = text.split(/\bto\b/i).map { |part| part.to_s.strip }.reject(&:empty?)
    recipient = parts.length > 1 ? parts.last : text
    recipient.empty? ? 'Unknown' : recipient
  end

  def StripeMethods::transfer_totals_by_recipient(report)
    totals = Hash.new(0)
    report[:transactions].each do |row|
      next unless row[:section] == 'Transfers'
      recipient = StripeMethods::transfer_recipient_from_description(row[:description])
      totals[recipient] += row[:amount_cents].to_i.abs
    end
    totals
  end

  def StripeMethods::period_metrics(report)
    by_section = report[:transactions].group_by { |row| row[:section] }
    sum_section = lambda { |name| (by_section[name] || []).sum { |row| row[:amount_cents].to_i } }

    {
      class_payments_cents: sum_section.call('Class Purchases'),
      point_rentals_cents: sum_section.call('Point Rentals'),
      packages_cents: sum_section.call('Packages'),
      event_tickets_cents: sum_section.call('Event Tickets'),
      room_rentals_cents: sum_section.call('Invoices'),
      paypal_income_cents: 0,
      paypal_expenses_cents: 0,
      refunds_cents: report[:summary][:refunds_cents].to_i.abs,
      stripe_fees_cents: report[:summary][:fees_cents].to_i.abs,
      transfer_totals_cents: StripeMethods::transfer_totals_by_recipient(report)
    }
  end

  def StripeMethods::recipient_normalized(name)
    name.to_s.downcase.gsub(/[^a-z0-9]/, '')
  end

  def StripeMethods::cosmic_fit_recipient?(name)
    normalized = StripeMethods::recipient_normalized(name)
    normalized.include?('cosmicfitclub')
  end

  def StripeMethods::cosmic_loft_recipient?(name)
    normalized = StripeMethods::recipient_normalized(name)
    normalized.include?('cosmicloft')
  end

  def StripeMethods::transfer_total_for(metrics, label)
    if label.to_s.downcase == 'cosmic fit club'
      return metrics[:transfer_totals_cents]
        .select { |name, _| StripeMethods::cosmic_fit_recipient?(name) }
        .values
        .sum
    end

    if label.to_s.downcase == 'cosmic loft'
      return metrics[:transfer_totals_cents]
        .select { |name, _| StripeMethods::cosmic_loft_recipient?(name) }
        .values
        .sum
    end

    key = metrics[:transfer_totals_cents].keys.find { |name| name.to_s.downcase == label.to_s.downcase }
    key ? metrics[:transfer_totals_cents][key].to_i : 0
  end

  def StripeMethods::metrics_value(metrics, key)
    cosmic_fit = StripeMethods::transfer_total_for(metrics, 'Cosmic Fit Club')
    cosmic_loft = StripeMethods::transfer_total_for(metrics, 'Cosmic Loft')
    others = metrics[:transfer_totals_cents]
      .reject { |name, _| StripeMethods::cosmic_fit_recipient?(name) || StripeMethods::cosmic_loft_recipient?(name) }
      .values
      .sum

    income_total =
      metrics[:class_payments_cents].to_i +
      metrics[:point_rentals_cents].to_i +
      metrics[:packages_cents].to_i +
      metrics[:event_tickets_cents].to_i +
      metrics[:room_rentals_cents].to_i +
      metrics[:paypal_income_cents].to_i

    expenses_total =
      metrics[:refunds_cents].to_i +
      metrics[:stripe_fees_cents].to_i +
      metrics[:paypal_expenses_cents].to_i +
      cosmic_loft + others

    if key.is_a?(String)
      return StripeMethods::transfer_total_for(metrics, key)
    end

    case key
    when :class_payments_cents then metrics[:class_payments_cents].to_i
    when :point_rentals_cents then metrics[:point_rentals_cents].to_i
    when :packages_cents then metrics[:packages_cents].to_i
    when :event_tickets_cents then metrics[:event_tickets_cents].to_i
    when :room_rentals_cents then metrics[:room_rentals_cents].to_i
    when :paypal_income_cents then metrics[:paypal_income_cents].to_i
    when :total_income_cents then income_total
    when :income_less_room_cents then income_total - metrics[:room_rentals_cents].to_i
    when :refunds_cents then metrics[:refunds_cents].to_i
    when :stripe_fees_cents then metrics[:stripe_fees_cents].to_i
    when :cosmic_fit_club_cents then cosmic_fit
    when :cosmic_loft_cents then cosmic_loft
    when :transfers_out_bank_cents then cosmic_fit
    when :other_transfer_total_cents then others
    when :chase_expenses_cents then metrics[:chase_expenses_cents].to_i
    when :paypal_expenses_cents then metrics[:paypal_expenses_cents].to_i
    when :total_expenses_cents then expenses_total
    when :net_cents then income_total - expenses_total
    when :net_less_loft_cents then (income_total - expenses_total) - cosmic_loft
    else
      nil
    end
  end

  def StripeMethods::report_from_transactions(transactions, from_date, to_date)
    by_type = transactions.group_by { |row| row[:type] }
    amount_for = lambda { |type| (by_type[type] || []).sum { |row| row[:amount_cents].to_i } }

    {
      from: from_date,
      to: to_date,
      summary: {
        gross_sales_cents: amount_for.call('charge'),
        refunds_cents: amount_for.call('refund'),
        disputes_cents: amount_for.call('payment_reversal') + amount_for.call('payment_failure_refund'),
        adjustments_cents: amount_for.call('adjustment') + amount_for.call('reserve_transaction'),
        payouts_cents: amount_for.call('payout'),
        transfers_cents: amount_for.call('transfer'),
        fees_cents: transactions.sum { |row| row[:fee_cents].to_i },
        net_cents: transactions.sum { |row| row[:net_cents].to_i }
      },
      transactions: transactions
    }
  end

  def StripeMethods::get_transactions(from, to)
    transactions = []
    Stripe::BalanceTransaction.list({ 
      created: StripeMethods::stripe_created_bounds(from, to), 
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

      description = StripeMethods::invoice_description_with_recipient(x.description.to_s, x.source, payment_type)
      
      transactions << [
        Time.at(x.created).to_s,
        x.type.to_s,
        payment_type,
        alt_description || description,
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
