data = {
  customer_id: 0,
  stripe_details: null
}

ctrl = {}

$(document).ready(function() {

  custy_selector = new CustySelector( id('custyselector_container') );
  custy_selector.ev_sub('customer_selected', function(custy_id) { data.customer_id = custy_id; get_stripe_data(); } );

  rivets.formatters.stripe_custy_link        = function(val) { return 'https://dashboard.stripe.com/customers/' + val;     }
  rivets.formatters.stripe_payment_link      = function(val) { return 'https://dashboard.stripe.com/payments/' + val;      }
  rivets.formatters.stripe_subscription_link = function(val) { return 'https://dashboard.stripe.com/subscriptions/' + val; }
  rivets.formatters.created_date             = function(val) { return new Date(val*1000).toDateString(); }
  rivets.bind(document.body, { data: data, ctrl: ctrl } );
  setup_history_api();

});

function setup_history_api() {
  var id = getUrlParameter('id') ? getUrlParameter('id') : 0;
  if( ! empty(id) ) { custy_selector.select_customer(id); }  
  history.replaceState( { "id": id }, "", 'payment_sources?id=' + id );

  $(window).bind('popstate', function(e) { 
    custy_selector.select_customer(history.state.id);
  });
}

function get_stripe_data() {
  $.get('/models/customers/' + data.customer_id + '/stripe_details', 'json')
   .success( function(resp) { data.stripe_details = resp; } )
   .fail( function(resp) { data.stripe_details = null; } )
}