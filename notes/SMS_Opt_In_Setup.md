# SMS Opt-In System Setup

## Database Migration Needed

Run this migration to add SMS opt-in fields to the customers table:

```ruby
Sequel.migration do
  change do
    alter_table(:customers) do
      add_column :sms_opt_in, TrueClass, default: false
      add_column :sms_opt_in_date, DateTime
      add_column :sms_opt_out_date, DateTime
    end
  end
end
```

Save this as a migration file in your migrations folder and run it.

## Twilio Webhook Configuration

Configure your Twilio phone number to send incoming SMS to:
- SMS Webhook URL: `https://cosmicfitclub.com/twilio/incoming_sms`
- Method: POST

This enables automatic handling of STOP, START, and HELP keywords.

## Files Created

1. `/site/pages/sms_opt_in/sms_opt_in.slim` - Public opt-in page
2. `/site/pages/sms_opt_in/sms_opt_in.js` - Page JavaScript
3. `/site/pages/sms_opt_in/sms_opt_in.css` - Page styling
4. `/admin/pages/sms_admin/sms_admin.slim` - Admin management page
5. `/admin/pages/sms_admin/sms_admin.js` - Admin page JavaScript  
6. `/models/Customers/CustomerSMS.rb` - SMS helper methods
7. Updated `/integrations/twilio.rb` - Added opt-in/opt-out routes
8. Updated `/site/CFC.rb` - Added SMS opt-in route
9. Updated `/admin/admin.rb` - Added admin SMS routes
10. Updated `/config.ru` - Added /sms route mapping

## Routes Added

### Public Routes
- `GET /sms/opt-in` - Display opt-in page (site)
- `GET /sms/status` - Get customer opt-in status
- `POST /sms/opt-in` - Process opt-in
- `POST /sms/opt-out` - Process opt-out

### Admin Routes
- `GET /admin/sms` - SMS admin dashboard
- `GET /admin/sms/subscribers` - List all opted-in subscribers
- `POST /admin/sms/send_test` - Send test SMS to admin
- `POST /admin/sms/send_individual` - Send SMS to specific customer
- `POST /admin/sms/send_bulk` - Send SMS to all opted-in customers

### Webhook Routes
- `POST /twilio/incoming_sms` - Handle incoming SMS (STOP/START/HELP keywords)

## Features

### Customer Opt-In Page
- User-friendly interface
- Login required
- Phone number verification
- Terms and conditions
- Confirmation message

### Automated Opt-Out
- Responds to STOP, UNSUBSCRIBE, CANCEL, END, QUIT keywords
- Updates database automatically
- Sends confirmation SMS

### Compliance
- TCPA compliant
- Clear opt-in language
- Easy opt-out mechanism
- Timestamp tracking

## Usage

### Sending SMS to Opted-In Customers

```ruby
# Send to single customer
customer = Customer[id]
customer.send_sms("Your message here") if customer.sms_opted_in?

# Send to all opted-in customers
Customer.sms_opted_in_list.each do |customer|
  send_sms_to("Your message", [customer.phone])
end

# Send to filtered group
Staff.active_teacher_list.each do |teacher|
  teacher.customer.send_sms("Teacher message") if teacher.customer.sms_opted_in?
end
```

### Checking Opt-In Status

```ruby
customer.sms_opted_in?  # Returns true/false
customer.sms_opt_in_date # When they opted in
customer.sms_opt_out_date # When they opted out (if applicable)
```

## Legal Compliance

### Required Opt-In Language
The system includes:
- Clear description of message frequency
- Statement that message and data rates may apply
- Easy opt-out instructions (text STOP)
- Help keyword (text HELP)
- Privacy policy link

### Best Practices
- Only send to opted-in customers
- Include opt-out instructions in first message
- Limit message frequency
- Keep messages relevant
- Don't share phone numbers

## Testing

1. Navigate to `/sms/opt-in` on your site
2. Log in with a test customer account
3. Enter phone number and opt in
4. Send test SMS to verify
5. Reply with "STOP" to test opt-out
6. Check database to confirm status changes
