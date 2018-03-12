data = {
  customers: [],
  amount: 0,
  payment_sources: []
}

$(document).ready( function() {

  setupCard();

  var form = document.getElementById('payment-form');
  form.addEventListener('submit', onFormSubmit );

  include_rivets_money();

  rivets.bind( $('body'), { data: data } );

  $.get('/models/customers', on_custylist, 'json');

  $('#customers').chosen();

  $('#customers').on('change', on_customer_selected );

});

/////////////////////// CARD /////////////////////////////////////////

function setupCard() {
  var elements = stripe.elements();

  card = elements.create('card', { 
    style: {
      base: {
        lineHeight: '1.5em',
        fontFamily: '"Industry-Light", sans-serif',
        fontWeight: 'bold',
        fontSmoothing: 'antialiased',
        fontSize: '1em',
        '::placeholder': { color: '#aab7c4' }
      },
      invalid: {
        color: '#fa755a',
        iconColor: '#fa755a'
      }
    }
  });

  card.mount('#card-element')

  card.addEventListener('change', onCardChange);
}

function onCardChange(e) {
  showErr(e.error);
  if(e.complete) {
    stripe.createToken(card).then(function(result) {
      showErr(result.error) 
      console.log(result);
    });
  }
}

function showErr(err) {
  var displayError = document.getElementById('card-errors');
  if( err ) { displayError.textContent = err.message; }
  else      { displayError.textContent = '';          }
}

function stripeTokenHandler(token) {
  console.log(token);
}

/////////////////////// CARD /////////////////////////////////////////


function onFormSubmit(e) {
  e.preventDefault();
  stripe.createToken(card).then( function(result){
    if( result.error ) {
      var errorElement = document.getElementById('card-errors');
      errorElement.textContext = result.error.message;
    }
    else {
      stripeTokenHandler(result.token);
    }

  });
}

function on_custylist(list) {
  data.customers = list;
}

function on_customer_selected(e) {
  console.log(parseInt(e.target.value));
  $.get(`/models/customers/${parseInt(e.target.value)}/payment_sources`,function(resp) {
    console.log(resp);
    data.payment_sources = resp;
  }, 'json');
}