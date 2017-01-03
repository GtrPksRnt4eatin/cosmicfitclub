$(document).ready( function() {
  
  var handler = StripeCheckout.configure({
    zipCode: true,
    locale: 'auto',
    billingAddress: true,
    key: STRIPE_PUBLIC_KEY,

    token: function(token) {
      data = {
        "type":  "package",
        "plan_id": PACKAGE['id'],
        "token": token
      }

      $.post('/stripe/charge', JSON.stringify( data ) )
        .done(function() {
          window.location.href = 'checkout/complete';
        })
        .fail(function() {
          alert('Your Card Has not Been Charged. You already have a Membership, Sign in to Modify it.')
        });
    }

  });

  id('checkout').addEventListener('click', function(e) {
    handler.open({
      name: 'Cosmic Fit Club',
      description: PACKAGE['name'],
      image: 'https://cosmicfit.herokuapp.com/background-blu.jpg',
      amount: PACKAGE['pass_price'] * PACKAGE['num_passes']
    })
  });

});
