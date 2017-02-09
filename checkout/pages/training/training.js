data = {
  id: 1,
  trainer: 'Phil',
  num_hours: 1,
  hour_price: 6000,
  total: 6000
}

$(document).ready( function() {

  rivets.formatters.currency = function(val) { return `$ ${(val/100).toFixed(2)}`; }
  rivets.bind( document.body, { data: data } )

  
  var handler = StripeCheckout.configure({
    zipCode: true,
    locale: 'auto',
    billingAddress: true,
    key: STRIPE_PUBLIC_KEY,

    token: function(token) {
      data = {
        "type":  "training",
        "id": data.id,
        "trainer": data.trainer,
        "num_hours": data.num_hours,
        "token": token
      }

      $.post('charge', JSON.stringify( data ) )
        .done(function() {
          window.location.href = '/checkout/complete';
        })
        .fail(function(e) {
          switch (e.status) {
            case 400: alert('There was an error processing the payment. Your Card Has not been charged.'); break;
            case 409: alert('Your Card Has not Been Charged. You already have a Membership, Sign in to Modify it.'); window.location.href = '/login'; break;
            case 500: alert('An Error Occurred!'); break;
            default: alert('huh???'); break;
          }
        });
    }

  });

  id('checkout').addEventListener('click', function(e) {
    handler.open({
      name: 'Cosmic Fit Club',
      description: `${data.num_hours} Personal Training Hours with ${data.trainer}`,
      image: 'https://cosmicfit.herokuapp.com/background-blu.jpg',
      amount: data.total
    })
  });

  id('num_hours').addEventListener('change', function(e) {
    data['num_hours'] = e.target.value;
    update_total();
  });

  $('.up').on('click', function(e) { data['num_hours'] += 1; update_total(); } )
  $('.dn').on('click', function(e) { data['num_hours'] = ( data['num_hours'] <= 1 ? 1 : data['num_hours'] - 1 ); update_total();   } )
});


function update_total() {
  data['total'] = data['num_hours'] * data['hour_price'];
}