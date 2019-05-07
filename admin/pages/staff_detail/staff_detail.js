data = {}

var ctrl = {}

$(document).ready(function() {

  rivets.formatters.subscription_link = function(val) { return '/admin/subscription?id=' + val; }
  
  include_rivets_dates();

  rivets.formatters.count = function(val) { return ( val ? val.length : 0 ); }

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

  get_staff_details();
  
});

function get_staff_details() {
  $.get( "/models/staff/" +  getUrlParameter('id') + "/details", function(resp) { data.staff = resp; });
}