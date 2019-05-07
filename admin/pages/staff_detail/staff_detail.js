data = {}

var ctrl = {}

$(document).ready(function() {

  rivets.formatters.subscription_link = function(val) { return '/admin/subscription?id=' + val; }

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

  get_staff_details();
  
});

function get_staff_details() {
  $.get( "/models/staff/" +  getUrlParameter('id') + "/detail_list", function(resp) { data.staff = resp; });
}