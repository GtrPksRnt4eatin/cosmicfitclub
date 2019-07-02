data = {
  customer: null,
  stripe_details: null
}

ctrl = {}

$(document).ready(function() {

  custy_selector = new CustySelector( id('custyselector_container') );
  custy_selector.ev_sub('customer_selected', function() { data.customer = custy_selector.selected_customer; get_stripe_data(); } );

  rivets.bind(document.body, { data: data, ctrl: ctrl } );
  get_stripe_data();

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
  $.get('/models/customer/' + data.customer_id + '/stripe_details', function(resp) { data.stripe_details = resp; }, 'json')
}