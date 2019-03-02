data = {
  subscription: {},
  uses: []
}

ctrl = {
}

$(document).ready(function(){
  include_rivets_dates();
  rivets.formatters.remove_invalid = function(val) { return val == "Invalid date" ? '' : val; }
  rivets.formatters.subscription_url = function(val) { return "https://dashboard.stripe.com/subscriptions/" + val; }
  rivets.formatters.customer_url = function(val) { return "/frontdesk/customer_file?id=" + val; }
  rivets.formatters.count = function(val) { return val.length; }
  rivets.bind(document.body, { data: data, ctrl: ctrl } );
  get_data();
});

function get_data() {
  $.get('/models/memberships/' + getUrlParameter('id') + '/details',  function(resp) {
  	data.subscription = resp;
  }, 'json')

  $.get('/models/memberships/' + getUrlParameter('id') + '/uses',  function(resp) {
    data.uses = resp;
  }, 'json')
}