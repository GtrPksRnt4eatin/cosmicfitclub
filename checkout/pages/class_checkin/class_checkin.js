$(document).ready( function() {

  include_rivets_dates();
  
  var binding = rivets.bind( $('body'), { data: data } );
  var stripe  = Stripe(STRIPE_PUBLIC_KEY);

  $('#customers').chosen();

  $('#customers').on('change', on_customer_selected );

  $('#create_sheet').on('click', on_create_sheet );
  
});

function on_customer_selected(e) {
  $.get(`/models/customers/${parseInt(e.target.value)}/class_passes`, function(resp) {
    data.customer.class_passes = resp;
  }, 'json');

  $.get(`/models/customers/${parseInt(e.target.value)}/status`, function(resp) {
    console.log(resp);
    data.customer.membership_status = resp;
    console.log(data.customer.membership_status);
  }, 'json');
}