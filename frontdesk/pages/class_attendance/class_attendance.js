data = {
  reservations: [],
  occurrence: {},
  frequent_flyers: [],
  staff_list: [],
  selected_customer: 0
}

ctrl = {
  delete: function(e,m) {
    if( data.reservations.length!=0 ) return;
    $.del('/models/classdefs/occurrences/' + data.occurrence.id, function() {  window.history.back(); }, 'json');
  },

  choose_flyer: function(e,m) {
    custy_selector.select_customer(e.target.value);
  },

  checkin: function(e,m) {
    $.post('/models/classdefs/reservations/' + m.reservation.id + '/checkin', get_reservations);
  },

	cancel: function(e,m) {
    var msg = { 
      "membership": "Undo Membership Use?",
      "class pass": m.reservation.pass_amount == 1 ? "Refund One Class Pass?" : `Refund ${m.reservation.pass_amount} Class Passes`,
      "card":       `Refund Credit Card \$ ${ m.reservation.payment_amount / 100 }?`,
      "cash":       `Refund \$ ${ m.reservation.payment_amount / 100 } Cash?`,
      "free":       "Cancel Registration?" 
    }[m.reservation.payment_type];
    if( !confirm(msg) ) return;
    $.del('/models/classdefs/reservations/' + m.reservation.id)
     .success( function() { get_reservations(); reservation_form.refresh_customer(); } );
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
        custy_selector.get_custy_list();
        custy_selector.select_customer(data.id);
      });
  },

  set_1x_price(e,m) {
    reservation_form.set_price(1200,1);
  },

  set_2x_price(e,m) {
    reservation_form.set_price(2400,2);
  }

}

$(document).ready( function() {

    get_occurrence_details();
    get_reservations();

    setup_bindings();
    
    userview          = new UserView( id('userview_container') );
    popupmenu         = new PopupMenu( id('popupmenu_container') );
    custy_selector    = new CustySelector( id('customer_form_container'));
    reservation_form  = new ReservationForm(id('reservation_form_container'));

    payment_form      = new PaymentForm();
    new_customer_form = new NewCustomerForm();
    teacher_selector  = new TeacherSelector();

    reservation_form.set_occurrence(data['occurrence']);
    reservation_form.ev_sub('reservation_made', get_reservations);
    reservation_form.ev_sub('paynow', function(args) { payment_form.checkout(args[0], args[1], args[2], args[3], args[4]) });

    payment_form.ev_sub('show', popupmenu.show );
    payment_form.ev_sub('hide', popupmenu.hide );
    popupmenu.ev_sub('close', payment_form.stop_listen_cardswipe);

    new_customer_form.ev_sub('show', popupmenu.show );
    new_customer_form.ev_sub('hide', popupmenu.hide );

    teacher_selector.ev_sub('show', popupmenu.show_modal);
    teacher_selector.ev_sub('select', change_teacher);
    teacher_selector.ev_sub('hide', popupmenu.hide );

    custy_selector.ev_sub('customer_selected', reservation_form.load_customer );
    custy_selector.ev_sub('customer_selected', function(val) { data.selected_customer = val; });

    get_frequent_fliers();

});

function setup_bindings() {
  include_rivets_dates();
  include_rivets_select();
  rivets.formatters.teachers         = function(val) { return empty(val) ? "" : val.map(    function(x) { return x.name         } ).join(', '); }
  rivets.formatters.head_count       = function(val) { return empty(val) ? "" : val.filter( function(x) { return !!x.checked_in } ).length;     }
  rivets.formatters.reg_count        = function(val) { return empty(val) ? "" : val.length; }
  rivets.formatters.money            = function(val) { return empty(val) ? "" : "$ " + (val/100).toFixed(2); }
  rivets.formatters.passes           = function(val) { return empty(val) ? "" : `(${val})`; }
  rivets.formatters.occurrence_href  = function(val) { return "/frontdesk/class_attendance/" + val; }
  rivets.formatters.saved_cards_href = function(val) { return "/admin/payment_sources?id=" + val; }
  var binding = rivets.bind( $('body'), { data: data, ctrl: ctrl } );
}

function get_reservations()    { 
  $.get('/models/classdefs/occurrences/' + occurrence_id + '/reservations', function(resp) { data['reservations'] = resp; }, 'json');  
}

function get_frequent_fliers() {
  $.get('/models/classdefs/occurrences/' + occurrence_id + '/frequent_flyers', function(resp) { data['frequent_flyers'] = resp; }, 'json'); 
}

function get_occurrence_details() {
  $.get('/models/classdefs/occurrences/' + occurrence_id + '/details', function(resp) { data['occurrence'] = resp; reservation_form.set_occurrence(data['occurrence']); }, 'json'); 
}

function change_teacher(staff_id) {
  payload = { "staff_id": staff_id, "starttime": data.occurrence.starttime, "classdef_id": data.occurrence.classdef_id };
  $.post('/models/classdefs/occurrences/' + data.occurrence.id, payload, function(resp) { data.occurrence = resp; }, 'json' );
}

function change_capacity(new_capacity) {
  payload = { }
}