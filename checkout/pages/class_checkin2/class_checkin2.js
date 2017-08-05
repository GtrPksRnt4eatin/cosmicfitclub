data['newsheet'] = {
  classdef_id: 0,
  staff_id: 0,
  starttime: null
}

data['query_date'] = new Date().setHours(0, 0, 0, 0);

ctrl = {
  datechange:      function(e,m) { get_occurrences(); },
  generate_sheets: function(e,m) { 
    var day = new Date(data['query_date']).toISOString();
    $.post(`/models/classdefs/generate?day=${day}`, get_occurrences); 
  }
}

$(document).ready( function() {

  setup_bindings();

  $('#customers').chosen();

  $('#customers').on('change', on_customer_selected );

  $('.sheets').on('click', '.sheet', on_sheet_click);

  get_occurrences();
});

function setup_bindings() {

  rivets.formatters.count = function(val) { return empty(val) ? 0 : val.length; }

  include_rivets_dates();
  var binding = rivets.bind( $('body'), { data: data, ctrl: ctrl } );

}

function on_customer_selected(e) {
  $.get(`/models/customers/${parseInt(e.target.value)}/class_passes`, function(resp) { data.customer.class_passes      = resp; }, 'json');
  $.get(`/models/customers/${parseInt(e.target.value)}/status`,       function(resp) { data.customer.membership_status = resp; }, 'json');
}

function get_occurrences() {
  var day = new Date(data['query_date']).toISOString();
  $.get(`/models/classdefs/occurrences?day=${day}`, on_occurrences, 'json');
}

function on_occurrences(resp) {
  data['occurrences'] = resp;
}

function on_sheet_click(e) {
  $(e.currentTarget).find('.hidden').toggle();
}