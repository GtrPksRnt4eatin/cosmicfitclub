# A2P 10DLC Campaign Approval Guide for Cosmic Fit Club

## Why Your Campaign Was Rejected

1. **Wrong Use Case**: "Low Volume Mixed" is meant for simple customer transactional messages. Your messages include staff notifications, which don't fit this category.

2. **Sample Messages Had Issues**:
   - Included specific payment amounts ($45.0, 2400card)
   - Showed personal email addresses
   - One sample was an opt-in request (suggesting no proper opt-in flow)
   - Messages looked too variable/dynamic (triggers fraud filters)

3. **Missing Opt-In Clarity**: Carriers need to see that users opted in BEFORE receiving messages, not as part of the first message.

## Recommended Approach: Split Into Two Campaigns

### Campaign 1: Customer Notifications
**Purpose**: Send to customers who register for classes

**Use Case**: Select **"Account Notifications"** (not Low Volume Mixed)

**Campaign Description**:
```
Cosmic Fit Club sends account notifications to customers regarding their fitness class bookings. Messages include registration confirmations, class reminders, schedule changes, and studio updates. All recipients explicitly opt-in through our website checkbox during account creation or via our SMS preferences page at cosmicfitclub.com/sms/opt-in. Messages are transactional and directly related to customer's booked services.
```

**Opt-In Process Description**:
```
Customers opt-in by checking a box during registration: "I agree to receive SMS notifications about my classes" or by visiting cosmicfitclub.com/sms/opt-in and submitting their phone number. Opt-in is stored with timestamp. Users can opt-out anytime by replying STOP.
```

**Opt-In Keywords**: `START, YES, SUBSCRIBE`
**Opt-Out Keywords**: `STOP, UNSUBSCRIBE, CANCEL, END, QUIT`
**Help Keywords**: `HELP, INFO`

**Sample Messages** (CRITICAL: Keep these generic and professional):
```
Sample 1: Your registration for Aerial Silks class on Dec 15 at 6:00 PM is confirmed. See you at Cosmic Fit Club! Reply STOP to opt out.

Sample 2: Reminder: Your Yoga Flow class starts in 1 hour. We look forward to seeing you! Reply STOP to opt out.

Sample 3: Important: Your scheduled class on Dec 18 has been rescheduled to Dec 19 at the same time. Reply STOP to opt out.

Sample 4: Thank you for joining us! Your next class: Hip Hop Dance on Dec 20 at 7 PM. Reply STOP to opt out.

Sample 5: Class Update: Tomorrow's 6 PM class will be held in Studio B instead of Studio A. Reply STOP to opt out.
```

**Embedded Links**: No
**Embedded Phone Numbers**: No  
**Age-Gated Content**: No
**Direct Lending**: No

**Monthly Message Volume**: Estimate 500-2000 (be realistic)

---

### Campaign 2: Staff/Teacher Notifications  
**Purpose**: Notify instructors when students register for their classes

**Use Case**: Select **"Agents and Franchises"** (for internal team communications)

**Campaign Description**:
```
Cosmic Fit Club sends operational notifications to verified employees and contract instructors. Messages notify teachers when students register for their classes, provide schedule updates, and communicate important work-related information. All recipients are staff members who opt-in during onboarding by providing their phone number and agreeing to receive work-related SMS. This is strictly for internal business operations between Cosmic Fit Club and its teaching staff.
```

**Opt-In Process Description**:
```
Staff members and instructors opt-in during onboarding by providing their phone number on an internal form and checking "I agree to receive work-related SMS notifications." Opt-in is verified by HR/management. Staff can opt-out by replying STOP or contacting HR directly.
```

**Sample Messages** (Keep it professional, no specific names/amounts):
```
Sample 1: New registration for your Hip Hop class on Dec 15 at 6 PM. Total students: 8. Reply STOP to opt out.

Sample 2: Schedule reminder: You're teaching Aerial Silks today at 7 PM. 12 students registered. Reply STOP to opt out.

Sample 3: Class Update: Your Dec 18 class has been moved to Studio B. Please arrive 15 minutes early. Reply STOP to opt out.

Sample 4: Staff Notice: Studio will close early on Dec 24. Please check updated schedule in staff portal. Reply STOP to opt out.

Sample 5: Registration Update: Your Saturday class is now full with 15 students. Waiting list available. Reply STOP to opt out.
```

**Embedded Links**: No
**Embedded Phone Numbers**: No
**Age-Gated Content**: No  
**Direct Lending**: No

**Monthly Message Volume**: Estimate 200-1000

---

## Required Code Changes

### 1. Clean Up Your SMS Messages

Your current messages include too much detail. Update them to be more generic:

**BEFORE** (Rejected):
```
Benjamin Klein (bklein261@gmail.com) bought a $45.0 ticket for Breathe Stretch Release.
```

**AFTER** (Approved):
```
New registration for your Breathe Stretch Release class. Total students: 5. Reply STOP to opt out.
```

### 2. Always Include Opt-Out Language

Every message MUST include opt-out instructions. Update your `send_sms_to` function:

```ruby
def send_sms_to(msg, numbers, include_optout = true)
  client = Twilio::REST::Client.new(ENV['TWILIO_SID'], ENV['TWILIO_AUTH_TOKEN'])
  
  # Append opt-out language if not already present
  if include_optout && !msg.include?('STOP')
    msg += " Reply STOP to opt out."
  end
  
  numbers.each do |num|
    client.messages.create(
      from: '+13476700019',
      to: num,
      body: msg
    )
  end
rescue Exception => e
  Slack.err("Twilio Error", e)
end
```

### 3. Implement Proper Opt-In (Already Done!)

Good news: You already created the opt-in page! Make sure it's live at:
- `https://cosmicfitclub.com/sms/opt-in`

### 4. Document Your Opt-In Process

Create a simple page showing your opt-in flow. Save screenshots:
1. Registration page with SMS checkbox
2. SMS preferences page (`/sms/opt-in`)
3. Database showing `sms_opt_in` field with timestamp

## Brand Registration Requirements

Make sure your **Brand** (not Campaign) has:
- ✅ Business name: Cosmic Fit Club
- ✅ Business type: Private Company
- ✅ EIN or Tax ID
- ✅ Business address
- ✅ Website: cosmicfitclub.com
- ✅ Business phone number
- ✅ Vertical: Fitness/Health & Wellness

## Submission Checklist

Before submitting:
- [ ] Sample messages are generic (no specific names, emails, or amounts)
- [ ] Every sample includes "Reply STOP to opt out"
- [ ] Campaign description mentions explicit opt-in
- [ ] Use case matches your actual usage (Account Notifications or Agents/Franchises)
- [ ] Monthly volume is realistic
- [ ] You can prove opt-in process if audited
- [ ] All embedded link/phone questions answered "No"

## After Approval

1. **Update your code** to match approved samples
2. **Test thoroughly** with your own phone numbers
3. **Monitor delivery rates** in Twilio console
4. **Keep opt-in records** for at least 4 years (compliance requirement)

## Pro Tips

- **Be Conservative**: Carriers prefer simple, clear messaging
- **Don't Over-Promise**: Start with lower volume estimates
- **Keep It Professional**: No slang, emojis, or casual language in samples
- **Match Your Usage**: Make sure your actual messages match approved samples
- **Document Everything**: Keep records of opt-ins and opt-outs

## If Rejected Again

You can appeal by:
1. Providing screenshots of your opt-in flow
2. Showing your privacy policy with SMS consent language
3. Explaining your business model more clearly
4. Offering to start with even lower volumes

Need the exact wording for anything? Let me know!
