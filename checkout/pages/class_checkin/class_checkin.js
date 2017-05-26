data['newsheet'] = {
  classdef_id: 0,
  staff_id: 0,
  starttime: null
}


$(document).ready( function() {

  include_rivets_dates();
  
  var binding = rivets.bind( $('body'), { data: data } );
  var stripe  = Stripe(STRIPE_PUBLIC_KEY);

  $('#customers').chosen();

  $('#customers').on('change', on_customer_selected );

  $('#create_sheet').on('click', on_create_sheet );

  $.get('/models/classdefs/occurrences', on_occurrences);
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

function on_create_sheet(e) {
  $.post(`/models/classdefs/occurrences`, data.newsheet,

  function(data) {
    console.log(data);
  }, 'json');
}

function on_occurrences(resp) {
  data['occurrences'] = JSON.parse(resp);
}