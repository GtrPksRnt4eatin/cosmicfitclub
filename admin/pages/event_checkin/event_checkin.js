ctrl = {
	check_in: function(e,m) {
	  var checkins = m.tic.checkins.filter( function(obj) { return obj.session_id == m.session.id } );
	  if( checkins.length > 0 ) {
	  	if( confirm(`Remove ${m.tic.customer.name} from ${m.session.title}?`) ) {
	  		var params = { id: checkins[0].id };
            $.post(`/models/events/tickets/${m.tic.id}/checkout`, params, update_data);
	  	}
	  }
	  else {
	  	if( confirm(`Checkin ${m.tic.customer.name} to ${m.session.title}?`) ) {
	    	var params = { event_id: m.tic.event_id, session_id: m.session.id, customer_id: m.tic.customer_id };
	    	$.post(`/models/events/tickets/${m.tic.id}/checkin`, params, update_data );
	    }
	  }
	}
}

$(document).ready(function() { 

  update_data();

  rivets.formatters.dayofwk    = function(val) { return moment(val).format('ddd') };
  rivets.formatters.date       = function(val) { return moment(val).format('MMM Do') };
  rivets.formatters.time       = function(val) { return moment(val).format('h:mm a') };
  rivets.formatters.simpledate = function(val) { return moment(val).format('MM/DD/YYYY hh:mm A') }; 

  rivets.formatters.has_session = function(val,session) {
  	return $.inArray(session.id, val.included_sessions);
  }

  rivets.formatters.checked_in = function(val,session) {
  	var checkins = val.checkins.filter(function(obj) { return obj.session_id == session.id } );
  	if(checkins.length > 0 ) {
	  return moment(checkins[0].timestamp).format('h:mm:ss a');
	}
  	else return "Check In Now";
  }

  rivets.formatters.headcount = function(val) {
    var x = 5;
  }

  rivets.formatters.checked_in_class = function(val, session) {
  	var checkins = val.checkins.filter(function(obj) { return obj.session_id == session.id } );
  	if(checkins.length > 0 ) { return 'checkedin' }
  	return 'checkedout';
  }

  rivets.bind($('#content'), { data: data, ctrl: ctrl } );  

});

function update_data() {
	$.get(`/models/events/${data['event'].id}/attendance`, on_attendance);
}

function on_attendance(attendance) { 
	data['list'] = JSON.parse(attendance); 
}