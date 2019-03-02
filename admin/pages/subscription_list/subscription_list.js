data = {
  subscriptions: {},
  filtered_subscriptions: {},
  filter_options: {
  	show_deactivated: false,
  	show_employees: false
  }
}

ctrl = {
  filter_subscriptions: function() { filter_list(); }
}

$(document).ready(function(){
  include_rivets_dates();
  rivets.formatters.remove_invalid = function(val) { return val == "Invalid date" ? '' : val; }
  rivets.formatters.subscription_url = function(val) { return "https://dashboard.stripe.com/subscriptions/" + val; }
  rivets.formatters.customer_url = function(val) { return "/frontdesk/customer_file?id=" + val; }
  rivets.formatters.employee = function(val) { return( val.plan_id == 10 ); }
  rivets.formatters.count = function(val) { return val.length; }
  rivets.bind(document.body, { data: data, ctrl: ctrl } );
  get_data();
});

function get_data() {
  $.get("/models/memberships/list", on_list, 'json')
}

function on_list(resp) {
  data['subscriptions'] = resp;
  filter_list();
}

function filter_list() {
  data.filtered_subscriptions = data.subscriptions.filter(function(sub) {
    if( sub.deactivated && !data.filter_options.show_deactivated ) return(false);
    if( sub.plan_id == 10 && !data.filter_options.show_employees ) return(false);
    return(true);
  });
}