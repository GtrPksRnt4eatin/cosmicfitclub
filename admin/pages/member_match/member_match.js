var data = {
  list: {}
}

var ctrl = {
	deactivate_free: function(e,m) {
		$.del(`/models/memberships/${m.item.id}`,function() { 
          data.list.cosmic_free.splice(m.index,1);
		});
	},
	deactivate_unlinked: function(e,m) {
        $.del(`/models/memberships/${m.item.id}`,function() { 
          data.list.cosmic_unmatched.splice(m.index,1);
		});
	},
	link_subscription: function(e,m) {
		if(e.target.value==0) { return false; }
		if(!confirm("Link Accounts?")) { return false; }
        $.post(`/models/memberships/${m.item.id}/stripe_id`, { value: e.target.value }, function() { location.reload(); } )
	},
}

$(document).ready(function() {

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

  get_match_list();
  
});

function get_match_list() {
  $.get('/models/memberships/matched_list', function(list) {
    data.list = JSON.parse(list);
  })
}