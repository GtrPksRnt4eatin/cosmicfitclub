ctrl = {

}

$(document).ready(function() { 

  $.get(`/models/events/${data['event'].id}/attendance`, on_attendance);

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

function on_attendance(attendance) { 
	data['list'] = JSON.parse(attendance); 
}