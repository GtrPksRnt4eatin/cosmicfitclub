ctrl = {
	check_in: function(e,m) {
	  var checkins = m.tic.checkins.filter( function(obj) { return obj.session_id == m.sess.id } );
	  if( checkins.length > 0 ) {
	  	if( confirm(`Remove ${m.tic.customer.name} from ${m.sess.title}?`) ) {
	  		var params = { id: checkins[0].id };
            $.post(`/models/events/tickets/${m.tic.id}/checkout`, params, update_data);
	  	}
	  }
	  else {
	  	if( confirm(`Checkin ${m.tic.customer.name} to ${m.sess.title}?`) ) {
	    	var params = { event_id: m.tic.event_id, session_id: m.sess.id, customer_id: m.tic.customer_id };
	    	$.post(`/models/events/tickets/${m.tic.id}/checkin`, params, update_data );
	    }
	  }
    cancelEvent(e);
    return false;
	},

  edit_tic: function(e,m) {
    document.location.href = '/admin/edit_ticket?id=' + m.tic.id;
  },

  edit_customer: function(e,m) {
    document.location.href = '/frontdesk/customer_file?id=' + ( m.tic.purchased_for ? m.tic.purchased_for : m.tic.customer_id );
  },

  edit_event(e,m) {
    document.location.href = '/admin/events/' + data.event.id;
  }
  
}

$(document).ready(function() { 

  update_data();

  initialize_rivets();

  payment_form     = new PaymentForm();
  popupmenu        = new PopupMenu( id('popupmenu_container') );

  tic_selector = new TicketSelector( id('ticketselector_container') );
  tic_selector.load_event_data(data['event']);

  custy_selector = new CustySelector( id('custyselector_container'), data['custylist'] );
  custy_selector.ev_sub('customer_selected', tic_selector.load_customer );

  payment_form.clear_customer();
  payment_form.ev_sub('show', popupmenu.show );
  payment_form.ev_sub('hide', popupmenu.hide );
  popupmenu.ev_sub('close', payment_form.stop_listen_cardswipe);

  tic_selector.ev_sub('paynow', function(args) {
    var custy = custy_selector.selected_customer;
    if(!custy) { alert('No Customer Selected!'); return; } 
    payment_form.checkout(args[0], args[1], args[2], args[3], args[4]) 
  });

  tic_selector.ev_sub('ticket_created', update_data);

});

function initialize_rivets() {

  include_rivets_money();
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
    if(empty(ticket.recipient)) { return empty(ticket.customer) ? '' : ticket.customer.name; }
    return ticket.recipient.name;
  }

  rivets.formatters.getemail = function(ticket) {
    if(empty(ticket.recipient)) { return empty(ticket.customer) ? '' : ticket.customer.email; }
    return ticket.recipient.email;
  }

  rivets.bind($('#content'), { data: data, ctrl: ctrl } );

}

function update_data() {
	$.get(`/models/events/${data['event'].id}/attendance`, on_attendance);
}

function on_attendance(attendance) { 
	data['list'] = attendance; 
}