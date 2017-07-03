data['newsheet'] = {
  classdef_id: 0,
  staff_id: 0,
  starttime: null
}


$(document).ready( function() {

  setup_bindings();

  var stripe  = Stripe(STRIPE_PUBLIC_KEY);

  $('#customers').chosen();

  $('#customers').on('change', on_customer_selected );

  $('#create_sheet').on('click', on_create_sheet );

  $('.sheets').on('click', '.sheet', on_sheet_click);

  $.get('/models/classdefs/occurrences', on_occurrences, 'json');
});

function setup_bindings() {

  rivets.formatters.count = function(val) { return empty(val) ? 0 : val.length; }

  include_rivets_dates();
  var binding = rivets.bind( $('body'), { data: data } );

}

function on_customer_selected(e) {
  $.get(`/models/customers/${parseInt(e.target.value)}/class_passes`, function(resp) { data.customer.class_passes      = resp; }, 'json');
  $.get(`/models/customers/${parseInt(e.target.value)}/status`,       function(resp) { data.customer.membership_status = resp; }, 'json');
}

function on_create_sheet(e) {
  $.post(`/models/classdefs/occurrences`, data.newsheet,

  function(data) {
    $.get('/models/classdefs/occurrences', on_occurrences);
  }, 'json');
}

function on_occurrences(resp) {
  data['occurrences'] = resp;
}

function on_sheet_click(e) {
  $(e.currentTarget).find('.hidden').toggle();
}