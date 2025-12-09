# Apple Pay Integration

## Overview
Added Apple Pay support to the PaymentForm component using Stripe's Payment Request API.

## Changes Made

### 1. Frontend - payment_form.js

#### New Methods:
- `init_apple_pay()` - Initializes the Payment Request API and checks if Apple Pay/Google Pay is available
- `on_payment_method(ev)` - Handles the payment when user completes Apple Pay authentication

#### Modified Methods:
- `init_stripe()` - Now calls `init_apple_pay()` after initializing the card element
- `checkout()` - Updates the Payment Request with the new amount and description
- `show()` - Mounts the Apple Pay button if available

#### New State Properties:
- `apple_pay_available` - Boolean flag indicating if Apple Pay is available on the device

#### HTML Changes:
Added a new table row for the Apple Pay button:
```html
<tr rv-if='this.apple_pay_available'>
  <th>Apple Pay</th>
  <td colspan='2'>
    <div id='payment-request-button'></div>
  </td>
</tr>
```

#### CSS Changes:
Added styling for the payment request button:
```css
.PaymentForm #payment-request-button {
  min-height: 40px;
}
```

### 2. Backend - paymentmethods.rb

#### New Method:
- `charge_payment_method` - Handles charges from Apple Pay payment methods
  - Creates a PaymentIntent with the payment method
  - Confirms the payment automatically
  - Records the payment in the database with type 'apple_pay'

### 3. Routes - checkout.rb

Added new POST route:
```ruby
post('/charge_payment_method') { charge_payment_method }
```

## How It Works

1. **Initialization**: When the payment form loads, it checks if Apple Pay is available on the device
2. **Display**: If available, the Apple Pay button appears at the top of the payment options
3. **Payment Flow**:
   - User clicks the Apple Pay button
   - Native Apple Pay sheet appears
   - User authenticates with Face ID/Touch ID/Passcode
   - Payment method is sent to `on_payment_method` handler
   - Frontend posts to `/checkout/charge_payment_method`
   - Backend creates and confirms PaymentIntent
   - Payment is recorded in database
   - Success/failure is communicated back to the user

## Device Compatibility

Apple Pay will automatically appear on:
- **Safari on iPhone/iPad** - Running iOS 10.1+
- **Safari on Mac** - Running macOS Sierra+ with Apple Pay enabled
- **Chrome on Android** - As Google Pay (using the same Payment Request API)

The button will NOT appear on:
- Desktop browsers without Apple Pay support
- Devices without Apple Pay configured

## Testing

### Test on Safari (Mac with Apple Pay):
1. Open the checkout page in Safari
2. The Apple Pay button should appear
3. Click it to see the Apple Pay sheet

### Test on iPhone:
1. Open the checkout page in Safari
2. Apple Pay button will be styled as a native Apple Pay button
3. Tap to authenticate and pay

### Test on other browsers:
- The button simply won't appear
- All other payment methods still work normally

## Backend Payment Processing

The payment is processed through Stripe's PaymentIntent API:
- More secure than the legacy Charge API
- Supports 3D Secure authentication automatically
- Returns a charge ID that's stored in CustomerPayment with type 'apple_pay'

## Notes

- The Payment Request API also supports Google Pay on Android devices
- The same button/code works for both Apple Pay and Google Pay
- No additional code needed - Stripe handles the differences
- The `return_url` parameter is required for some payment methods but not used for Apple Pay
- Payments are marked as 'apple_pay' type in the database for easy reporting
