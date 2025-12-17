class Customer < Sequel::Model

  # SMS Opt-In Methods
  
  def sms_opted_in?
    self.sms_opt_in == true && (self.sms_opt_out_date.nil? || self.sms_opt_in_date > self.sms_opt_out_date)
  end
  
  def opt_in_to_sms(phone = nil)
    update(
      sms_opt_in: true,
      sms_opt_in_date: DateTime.now,
      phone: phone || self.phone
    )
    
    # Send confirmation SMS
    send_sms_confirmation
  end
  
  def opt_out_of_sms
    update(
      sms_opt_in: false,
      sms_opt_out_date: DateTime.now
    )
    
    # Send opt-out confirmation
    send_sms_optout_confirmation
  end
  
  def send_sms(message)
    return false unless sms_opted_in?
    return false unless phone
    
    send_sms_to(message, [phone])
    true
  rescue => e
    Slack.err("SMS Send Error", e)
    false
  end
  
  def send_sms_confirmation
    message = "Welcome to Cosmic Fit Club SMS! You'll receive class reminders, updates & promotions. Reply STOP to unsubscribe, HELP for help. Msg&data rates may apply."
    send_sms_to(message, [phone])
  rescue => e
    Slack.err("SMS Confirmation Error", e)
  end
  
  def send_sms_optout_confirmation
    message = "You've been unsubscribed from Cosmic Fit Club SMS. You will no longer receive text messages. Text START to re-subscribe."
    send_sms_to(message, [phone])
  rescue => e
    Slack.err("SMS Opt-Out Confirmation Error", e)
  end
  
  # Class methods
  
  def self.sms_opted_in_list
    Customer.where(sms_opt_in: true)
            .where(Sequel.|({ sms_opt_out_date: nil }, Sequel.lit('sms_opt_in_date > sms_opt_out_date')))
            .all
  end
  
  def self.sms_opted_in_count
    sms_opted_in_list.count
  end
  
  def self.find_by_phone(phone)
    # Normalize phone number (remove formatting)
    normalized = phone.gsub(/\D/, '')
    Customer.where(Sequel.like(:phone, "%#{normalized}%")).first
  end
  
end
