require 'stripe'

class StripeRoutes < Sinatra::Base

  # Create a new Stripe Connect vendor account and return onboarding link
  post '/create_vendor_account' do

    staff_id = params['staff_id']
    staff = Staff[staff_id] or halt(404, "Staff member not found")
    
    result = StripeMethods::create_new_vendor_account(staff.email)
    staff.update( stripe_connect_id: result[:id] )

    return result[:onboarding_url]

  rescue => e
    Slack.err("Stripe Vendor Creation Error", e)
    status 500
    { success: false, error: e.message }.to_json
  end

  # Refresh URL - regenerate link if original expires
  get '/vendor_refresh' do
    "The onboarding link has expired. Please contact support for a new link."
  end

  # Return URL - vendor completes onboarding
  get '/vendor_complete' do
    "Thank you! Your account setup is complete. We'll be in touch shortly."
  end

  post '/webhook' do

    event = JSON.parse request.body.read

    case event['type']

    when 'customer.subscription.created'

      customer = Customer.find( :stripe_id => event['data']['object']['customer'] )

      Subscription.find_or_create( :stripe_id=>event['data']['object']['id'] ) { |sub| 
        sub.plan_id = Plan.find( :stripe_id => event['data']['object']['plan']['id'] ).try(:id)
        sub.customer_id = customer.id
      }

      Slack.post("#{customer.to_list_string} Subscription Created!")

    when 'customer.subscription.deleted'

      customer = Customer.find( :stripe_id => event['data']['object']['customer'] )
      subscription = Subscription.find( :stripe_id => event['data']['object']['id'] )
      subscription.cancel unless subscription.nil?
      Slack.post("#{customer.try(:to_list_string)} Subscription Deleted!")

    when 'customer.subscription.trial_will_end'

      customer = Customer.find( :stripe_id => event['data']['object']['customer'] ) 
      Slack.post("#{customer.to_list_string} Trial Ending on #{Time.at(event['data']['object']['trial_end']).to_s}")

    when 'invoice.upcoming'

      customer = Customer.find( :stripe_id => event['data']['object']['customer'] ) 
      Slack.post("#{customer.to_list_string} #{event['data']['object']['total']} Payment Due On #{Time.at(event['data']['object']['trial_end'].to_i).to_s}")

    when 'invoice.payment_succeeded', 'invoice.paid'

      #event['data']['object']['id']
      #event['data']['object']['customer_name']
      #event['data']['object']['customer_email']

      #event['data']['object']['amount_due']
      #event['data']['object']['amount_paid']

      #event['data']['object']['hosted_invoice_url']
      
      Slack.loft("Invoice Paid: \n#{event['data']['object']['customer_name']} [#{event['data']['object']['customer_email']}]\nPaid $#{event['data']['object']['amount_paid']} / $#{event['data']['object']['amount_due']}\n#{event['data']['object']['description']}")

    else

      Slack.post("Stripe Webhook: #{ event['type'] }")

    end

  end

  error Stripe::CardError do
    env['sinatra.error'].message
  end

end