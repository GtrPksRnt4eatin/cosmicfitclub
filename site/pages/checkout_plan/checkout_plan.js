$(document).ready( function() {
  
  var handler = StripeCheckout.configure({
    zipCode: true,
    locale: 'auto',
    billingAddress: true,
    key: STRIPE_PUBLIC_KEY,

    token: function(token) {
      data = {
        "type":  "plan",
        "plan_id": PLAN['id'],
        "token": token
      }

      $.post('/stripe/charge', JSON.stringify( data ) );
    }

  });

  id('checkout').addEventListener('click', function(e) {
    handler.open({
      name: 'Cosmic Fit Club',
      description: PLAN['name'],
      image: 'https://cosmicfit.herokuapp.com/background-blu.jpg',
      amount: PLAN['price'] * PLAN['term_months']
    })
  });

});