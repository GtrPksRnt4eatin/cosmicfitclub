# Pricing Page Update - Payment Form Integration

## Overview
Updated the pricing page to use the modern `PaymentForm` component instead of linking to separate checkout pages.

## Changes Made

### 1. pricing.slim

#### Added Stripe Initialization:
```slim
script src='https://js.stripe.com/v3/'
javascript:
  var STRIPE_PUBLIC_KEY = '#{ ENV['STRIPE_PUBLIC'] }';
  var stripe = Stripe(STRIPE_PUBLIC_KEY);
  var elements = stripe.elements();
```

#### Added Required Scripts:
- `/admin/elements/popup_menu` - For modal display
- `/checkout/elements/payment_form` - The payment form component

#### Updated Buy Buttons:
Changed from links to buttons with data attributes:
```slim
button data-type='pack' data-id='#{pack[:id]}' data-name='#{pack[:name]}' data-amount='#{pack[:pass_price] * pack[:num_passes]}' class='buy-button' Buy Now
```

#### Added Popup Container:
```slim
#popupmenu_container
```

### 2. pricing.js

#### Complete Rewrite:
- Initializes `UserView`, `PopupMenu`, and `PaymentForm` components
- Handles login check before showing payment form
- Processes payment through the payment form modal
- Completes purchase after successful payment

#### Key Functions:

**Buy Button Handler:**
- Checks if user is logged in
- Opens payment form with package/plan details
- Passes callback for after successful payment

**completePurchase():**
- Called after payment is successful
- Posts to appropriate endpoint with payment_id
- Redirects to completion page

## User Flow

1. **User clicks "Buy Now"** on any package/plan
2. **Login Check**: If not logged in, shows login modal
3. **Payment Form**: Opens modal with payment options:
   - Apple Pay (if available)
   - Saved cards
   - New card entry
   - Cash (for front desk)
4. **Payment Processing**: User completes payment
5. **Purchase Completion**: Backend assigns package/plan to user
6. **Redirect**: User sees completion page

## Benefits

✅ **Unified Experience**: Same payment flow across the site
✅ **Apple Pay Support**: Now available on pricing page
✅ **Modal Interface**: No page redirects, smoother UX
✅ **Login Integration**: Seamlessly handles non-logged-in users
✅ **Modern Payment API**: Uses Stripe Elements instead of legacy Checkout

## Backend Integration

The pricing page now uses these existing endpoints:
- `/checkout/pack/buy` - For package purchases (uses `buy_pack_precharged`)
- `/checkout/plan/charge` - For plan subscriptions

Both endpoints expect:
- `pack_id` or `plan_id`
- `payment_id` (the Stripe charge ID from CustomerPayment)

## Testing

1. **Not logged in**: Should prompt for login first
2. **Apple Pay**: Should show Apple Pay button on compatible devices
3. **Saved cards**: Should show any saved payment methods
4. **New card**: Should allow entering new card details
5. **Purchase completion**: Should redirect to /checkout/complete
