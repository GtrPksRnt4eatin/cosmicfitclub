data = {
  subscriptions: {},
  filtered_subscriptions: {},
  filter_options: {
  	show_deactivated: false
  }
}

ctrl = {
	
}

$(document).ready(function(){
  rivets.bind(document.body, { data: data, ctrl: ctrl } );
  get_data();
});

function get_data() {
  $.get("/models/memberships/grouped_list", on_list, 'json')
}

function on_list(resp) {
  data['subscriptions'] = resp;
  filter_list();
}

function filter_list() {
  data.filtered_subscriptions = data.subscriptions.filter(function(sub) {
    if( data.filter_options.show_deactivated && sub.deactivated ) return(false);
    return(true);
  });
}