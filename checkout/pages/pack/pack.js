$(document).ready( function() {
  
  var handler = StripeCheckout.configure({
    locale: 'auto',
    key: STRIPE_PUBLIC_KEY,

    token: function(token) {
      data = {
        "type":  "package",
        "pack_id": PACKAGE['id'],
        "token": token
      }

      $.post('charge', JSON.stringify( data ) )
        .done(function() {
          window.location = '/checkout/complete';
        })
        .fail(function(e) {
          switch (e.status) {
            case 400: alert('There was an error processing the payment. Your Card Has not been charged.'); break;
            case 500: alert('An Error Occurred!'); break;
            default: alert('huh???'); break;        
          }
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
