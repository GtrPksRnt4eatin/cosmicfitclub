data = {
  subscriptions: {}
}

ctrl = {
	
}

$(document).ready(function(){
  rivets.bind(document.body, { data: data, ctrl: ctrl } );
  get_data();
});

function get_data() {
  $.get("/models/memberships/grouped_list", on_list )
}

function on_list(resp) {
  data['subscriptions'] = resp;
}