data = {
  customers: [],
  customer: {
    payment_sources: [],
    class_passes: [],
    membership_status: null
  },
  amount: 0,
  starttime: null
}

$(document).ready( function() {

  setupCard();

  var form = document.getElementById('payment-form');
  form.addEventListener('submit', onFormSubmit );

  include_rivets_money();
  include_rivets_dates();

  rivets.formatters.count = function(val) { return val.length; }

  rivets.bind( $('body'), { data: data } );

  $.get('/models/customers', on_custylist, 'json');

  $('#customers').chosen();
  $('#classes').chosen();

  $('#customers').on('change', on_customer_selected );

  $('ul.tabs li').click(function(){
    var tab_id = $(this).attr('data-tab');

    $('ul.tabs li').removeClass('current');
    $('.tab-content').removeClass('current');

    $(this).addClass('current');
    $("#"+tab_id).addClass('current');
  });

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
  resetCustomer();
  data.customer.id = parseInt(e.target.value);
  $.get(`/models/customers/${parseInt(e.target.value)}/payment_sources`,function(resp) {
    data.customer.payment_sources = resp;
  }, 'json');

  $.get(`/models/customers/${parseInt(e.target.value)}/class_passes`, function(resp) {
    data.customer.class_passes = resp;
  }, 'json');

  $.get(`/models/customers/${parseInt(e.target.value)}/status`, function(resp) {
    console.log(resp);
    data.customer.membership_status = resp;
    console.log(data.customer.membership_status);
  }, 'json');
}

function resetCustomer() {
  data.customer.payment_sources = [];
  data.customer.class_passes = [];
  data.customer.membership_status = null;
}