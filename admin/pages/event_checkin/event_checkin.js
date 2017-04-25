ctrl = {
	check_in: function(e,m) {
	  var params = { event_id: m.tic.event_id, session_id: m.session.id, customer_id: m.tic.customer_id }
	  $.post(`/models/events/tickets/${m.tic.id}/checkin`, obj_to_formdata(params) );
	}
}

$(document).ready(function() { 

  update_data();

  rivets.formatters.dayofwk    = function(val) { return moment(val).format('ddd') };
  rivets.formatters.date       = function(val) { return moment(val).format('MMM Do') };
  rivets.formatters.time       = function(val) { return moment(val).format('h:mm a') };
  rivets.formatters.simpledate = function(val) { return moment(val).format('MM/DD/YYYY hh:mm A') }; 

  rivets.formatters.has_session = function(val,session) {
  	return val.included_sessions.includes(session.id);
  }

  rivets.formatters.checked_in = function(val,session) {
  	return true;
  }

  rivets.bind($('#content'), { data: data, ctrl: ctrl } );  

});

function update_data() {
	$.get(`/models/events/${data['event'].id}/attendance`, on_attendance);
	var x = 5;
}

function on_attendance(attendance) { 
	data['list'] = JSON.parse(attendance); 
}