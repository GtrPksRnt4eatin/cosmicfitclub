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
    cancelEvent(e);
    return false;
	},

  edit_tic: function(e,m) {
    document.location.href = '/admin/tickets/' + m.tic.id;
  }
}

$(document).ready(function() { 

  update_data();
  
  $('#customers').chosen({ search_contains: true });

  initialize_rivets();

  tic_selector = new TicketSelector( id('ticketselector_container') );
  tic_selector.load_event_data(data['event']);

  custy_selector = new CustySelector( id('custyselector_container'), data['custylist'] );
  custy_selector.ev_sub('customer_selected', tic_selector.load_customer );

});

function initialize_rivets() {

  include_rivets_dates();
  include_rivets_select();

  rivets.formatters.has_session = function(val,session) {
    return $.inArray(session.id, val.included_sessions)>-1;
  }

  rivets.formatters.checked_in = function(val,session) {
    if(empty(val.checkins)) { return "Check In Now"; }
    var checkins = val.checkins.filter(function(obj) { return obj.session_id == session.id } );
    if(checkins.length > 0 ) { return moment(checkins[0].timestamp).format('h:mm:ss a'); }
    else return "Check In Now";
  }

  rivets.formatters.checked_in_class = function(val, session) {
    if(empty(val.checkins)) { return 'checkedout' }
    var checkins = val.checkins.filter(function(obj) { return obj.session_id == session.id } );
    if(checkins.length > 0 ) { return 'checkedin' }
    return 'checkedout';
  }

  rivets.formatters.headcount = function(val, session) {
    return val.filter( function(tic) { 
      return $.inArray(session.id, tic.included_sessions)>-1 
    }).length;
  }

  rivets.formatters.getname = function(ticket) {
    if(empty(ticket.recipient)) { return ticket.customer.name; }
    return ticket.recipient.name;
  }

  rivets.formatters.getemail = function(ticket) {
    if(empty(ticket.recipient)) { return ticket.customer.email; }
    return ticket.recipient.email;
  }

  rivets.bind($('#content'), { data: data, ctrl: ctrl } );

}

function update_data() {
	$.get(`/models/events/${data['event'].id}/attendance`, on_attendance);
}

function on_attendance(attendance) { 
	data['list'] = JSON.parse(attendance); 
}