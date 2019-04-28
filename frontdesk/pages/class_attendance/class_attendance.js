data = {
  reservations: [],
  occurrence: {},
  frequent_fliers: [],
  staff_list: []
}

ctrl = {

  edit_occurrence(e,m) {
    
  },

  change_teacher(e,m) {
    payload = { "staff_id": parseInt(e.target.value), "starttime": data.occurrence.starttime, "classdef_id": data.occurrence.classdef_id };
    $.post('/models/classdefs/occurrences/' + data.occurrence.id, JSON.stringify(payload), function(resp) { data.occurrence = resp; } );
  },

  checkin: function(e,m) {
    $.post(`/models/classdefs/reservations/${m.reservation.id}/checkin`, get_reservations);
  },

	cancel: function(e,m) {
		var proceed;
		if( m.reservation.payment_type == 'membership' ) { proceed = confirm("Undo Membership Use?");   }
		if( m.reservation.payment_type == 'class pass' ) { proceed = confirm("Refund One Class Pass?"); }
		if( m.reservation.payment_type == 'card'       ) { proceed = confirm("Refund Credit Card?");    }
    if( m.reservation.payment_type == 'cash'       ) { proceed = confirm("Refund $25 Cash?");       }
    if( m.reservation.payment_type == 'free'       ) { proceed = confirm("Cancel Registration?");   }
		if( !proceed ) return;
		$.del(`/models/classdefs/reservations/${m.reservation.id}`, function() { get_reservations(); reservation_form.refresh_customer(); } );
	},

  edit_reservation_customer(e,m) {
    window.location.href = '/frontdesk/customer_file?id=' + m.reservation.customer_id
  },

  edit_customer(e,m) {
    window.location.href = '/frontdesk/customer_file?id=' + $('#customers').val();
  },

  new_customer(e,m) {
    var name = prompt("Enter The New Customers Name:", "");
    var email = prompt("Enter The New Customers E-Mail:", "");
    $.post('/auth/register', JSON.stringify({
        "name": name,
        "email": email
      }), 'json')
     .fail( function(req,msg,status) { 
        alert(req.responseText);
      })
     .success( function(data) {
        console.log(data);
        var option = document.createElement("option");
        option.text = name + ' ( ' + email + ' ) ';
        option.value = data.id;
        id('customers').add(option);
        $('#customers').val(data.id);
        $('#customers').trigger('chosen:updated');
        reservation_form.load_customer(data.id);
      });
  }

}

$(document).ready( function() {

    setup_bindings();
    
    userview         = new UserView( id('userview_container') );
    popupmenu        = new PopupMenu( id('popupmenu_container') );
    reservation_form = new ReservationForm(id('reservation_form_container'));
    payment_form     = new PaymentForm();

    reservation_form.set_occurrence(data['occurrence']);
    reservation_form.ev_sub('reservation_made', get_reservations);
    reservation_form.ev_sub('paynow', function(args) { payment_form.checkout(args[0], args[1], args[2], args[3], args[4]) });

    payment_form.ev_sub('show', popupmenu.show );
    payment_form.ev_sub('hide', popupmenu.hide );
    popupmenu.ev_sub('close', payment_form.stop_listen_cardswipe);

    $('#customers').on('change', reservation_form.load_customer );
    get_occurrence_details();
    get_reservations();
    get_frequent_fliers();
    get_staff_list();

});

function setup_bindings() {
  include_rivets_dates();
  include_rivets_select();
  rivets.formatters.teachers = function(val) { return empty(val) ? "" : val.map(function(x) { return x.name } ).join(', '); }
  var binding = rivets.bind( $('body'), { data: data, ctrl: ctrl } );
}

function get_reservations()    { 
  $.get('/models/classdefs/occurrences/' + occurrence_id + '/reservations', function(resp) { data['reservations'] = resp; }, 'json');  
}

function get_frequent_fliers() {
  $.get('/models/classdefs/occurrences/' + occurrence_id + '/frequent_fliers', function(resp) { data['frequent_fliers'] = resp; }, 'json'); 
}

function get_occurrence_details() {
  $.get('/models/classdefs/occurrences/' + occurrence_id + '/details', function(resp) { data['occurrence'] = resp; reservation_form.set_occurrence(data['occurrence']); }, 'json'); 
}

function get_staff_list() {
  $.get('/models/staff', function(resp) { data['staff_list'] = resp; }, 'json');
}

//function get_customers() {
//  $.get('/models/customers/list', function(val) { data.customers = val; }, 'json');
//}
