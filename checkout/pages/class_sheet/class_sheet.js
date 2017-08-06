ctrl = {

  checkin: function(e,m) {
    $.post(`/models/classdefs/reservations/${m.reservation.id}/checkin`, get_reservations);
  },

	cancel: function(e,m) {
		var proceed;
		if( m.reservation.payment_type == 'membership' ) { proceed = true; }
		if( m.reservation.payment_type == 'class pass' ) { proceed = confirm("Refund One Class Pass?"); }
		if( m.reservation.payment_type == 'card'       ) { proceed = confirm("Refund Credit Card?");    }
    if( m.reservation.payment_type == 'cash'       ) { proceed = confirm("Refund $25 Cash?");       }
		if( !proceed ) return;
		$.del(`/models/classdefs/reservations/${m.reservation.id}`, function() { get_reservations(); reservation_form.refresh_customer(); } );
	}

}

$(document).ready( function() {

    setup_bindings();

    payment_form     = new PaymentForm();
    popupmenu        = new PopupMenu( id('popupmenu_container') );
    reservation_form = new ReservationForm(id('reservation_form_container'));

    reservation_form.set_occurrence(data['occurrence']);
    reservation_form.ev_sub('reservation_made', get_reservations);
    reservation_form.ev_sub('paynow', function(args) { payment_form.checkout(args[0],args[1],args[2],args[3],args[4]) });

    payment_form.ev_sub('show', popupmenu.show );
    payment_form.ev_sub('hide', popupmenu.hide );
    popupmenu.ev_sub('close', payment_form.stop_listen_cardswipe);

    $('#customers').chosen();
    $('#customers').on('change', reservation_form.load_customer );

});

function setup_bindings() {
  include_rivets_dates();
  var binding = rivets.bind( $('body'), { data: data, ctrl: ctrl } );
}

function get_reservations()    { 
  $.get(`/models/classdefs/occurrences/${data['occurrence'].id}/reservations`, function(resp) { data['reservations'] = resp; }, 'json');  
}