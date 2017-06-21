data = {
  customers: [],
  customer: {
    payment_sources: [],
    class_passes: [],
    membership_status: null
  },
  reservation: {
    customer_id: 0,
    classdef_id: 0,
    staff_id: 0,
    starttime: null,
  },
  amount: 0,
  starttime: null
}

ctrl = {

  reserve_class_pass: function(e,m) {
    $.post('/models/classdefs/reservation', data.reservation)
     .done( function(e) { refresh_customer_data(); clear_reservations(); } )
     .fail( function(e) { alert('reservation failed!'); });
  },

  reserve_membership: function(e,m) {
    data = {
      
    }
    $.post('models/classdefs/reservation', data, 'json');
  },

  reserve_card: function(e,m) {

  },

  reserve_cash: function(e,m) {

  }

}

$(document).ready( function() {

  setupCard();

  var form = document.getElementById('payment-form');
  form.addEventListener('submit', onFormSubmit );

  setupBindings();

  $.get('/models/customers', on_custylist, 'json');

  $('#customers').chosen();
  $('#classes').chosen();
  $('#staff').chosen();

  $('#customers').on('change', on_customer_selected );

  $('ul.tabs li').click(function(){
    var tab_id = $(this).attr('data-tab');

    $('ul.tabs li').removeClass('current');
    $('.tab-content').removeClass('current');

    $(this).addClass('current');
    $("#"+tab_id).addClass('current');
  });

});

function setupBindings() {
  include_rivets_money();
  include_rivets_dates();
  include_rivets_select();

  rivets.formatters.count = function(val) { return empty(val) ? 0 : val.length; }
  rivets.formatters.zero_if_null = function(val) { return empty(val) ? 0 : val; }
  rivets.formatters.has_membership = function(val) { return( empty(val) ? false : val.name != 'None' ); }

  rivets.bind( $('body'), { data: data, ctrl: ctrl } );
}

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
  data.reservation.customer_id = e.target.value;
  data.customer.id = parseInt(e.target.value);
  refresh_customer_data();
}

function clear_reservations() {
  data.reservation.classdef_id=0;
  data.reservation.staff_id=0;
  data.reservation.starttime=null;
}

function refresh_customer_data() {
  $.get(`/models/customers/${data.customer.id}/payment_sources`, function(resp) { data.customer.payment_sources   = resp; }, 'json');
  $.get(`/models/customers/${data.customer.id}/class_passes`,    function(resp) { data.customer.class_passes      = resp; }, 'json');
  $.get(`/models/customers/${data.customer.id}/status`,          function(resp) { data.customer.membership_status = resp; }, 'json');
  $.get(`/models/customers/${data.customer.id}/reservations`,    function(resp) { data.customer.reservations      = resp; }, 'json');
}

function resetCustomer() {
  data.customer.payment_sources = [];
  data.customer.class_passes = [];
  data.customer.membership_status = null;
}