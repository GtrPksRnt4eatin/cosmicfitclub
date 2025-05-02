data = {
  reservations: [],
  occurrence: {},
  frequent_flyers: [],
  staff_list: [],
  selected_customer: 0,
  events: [],
  lesson: false
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

  use_teacher_pass: function(e,m) {
    reservation_form.set_price(1200,1);
    reservation_form.post_reservation("teacher_pass");
  },

  cancel: function(e,m) {
    var proceed;
    var data = { to_passes: false };
    switch(m.reservation.payment_type) {
      case "membership": 
        proceed = confirm("Undo Membership Use?");
        break;
      case "class pass":
        proceed = confirm( m.reservation.pass_amount == 1 ? "Refund One Class Pass?" : `Refund ${m.reservation.pass_amount} Class Passes`);
        break;
      case "free":
        proceed = confirm( "Cancel Registration?" );
        break;
      case "card":
        proceed = confirm( `Credit ${ Math.ceil( m.reservation.payment_amount / 1200 ) } Passes? Cancel to Refund` );
        if(proceed) { data.to_passes = true; break; }
        proceed = confirm( `Refund Credit Card \$ ${ m.reservation.payment_amount / 100 }?` )
        break;
      case "cash":
        proceed = confirm( `Credit ${ Math.ceil( m.reservation.payment_amount / 1200 ) } Passes? Cancel to Refund` );
        if(proceed) { data.to_passes = true; break; }
        proceed = confirm( `Refund \$ ${ m.reservation.payment_amount / 100 } Cash?` )
        break;
    }
    if(!proceed) return;
    $.del('/models/classdefs/reservations/' + m.reservation.id, data)
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
    if(name==null) return;
    var email = prompt("Enter The New Customers E-Mail:", "");
    if(email==null) return;
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
  },

  set_90min_price(e,m) {
    reservation_form.set_price(1800,1.5);
  },

  set_3x_price(e,m) {
    reservation_form.set_price(3600,3);
  },

  datechange(e,m) {
    if(!data.occurrence.location) { return; }
    var starttime = moment(data.occurrence.starttime).toISOString();
    change_starttime(starttime);
  },

  buy_package(pack) {
    var x = pack;
  }

}

$(document).ready( function() {

    get_occurrence_details();
    get_reservations();

    setup_bindings();
    
    userview          = new UserView( id('userview_container') );
    popupmenu         = new PopupMenu( id('popupmenu_container') );
    custy_selector    = new CustySelector( id('customer_form_container'), true, false);
    reservation_form  = new ReservationForm(id('reservation_form_container'));

    payment_form      = new PaymentForm();
    new_customer_form = new NewCustomerForm();
    teacher_selector  = new TeacherSelector();
    location_selector = new LocationSelector();

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

    location_selector.ev_sub('show', popupmenu.show_modal);
    location_selector.ev_sub('select', change_location);
    location_selector.ev_sub('hide', popupmenu.hide );

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
  binding = rivets.bind( $('body'), { data: data, ctrl: ctrl } );
}

function get_reservations()    { 
  $.get('/models/classdefs/occurrences/' + occurrence_id + '/reservations', function(resp) { data['reservations'] = resp; }, 'json');  
}

function get_frequent_fliers() {
  $.get('/models/classdefs/occurrences/' + occurrence_id + '/frequent_flyers', function(resp) { data['frequent_flyers'] = resp; }, 'json'); 
}

function get_calendar_events(day) {
  $.get(`/models/groups/gcal_events?day=${day}`, function(resp) { data.events = resp; }); 
}

function get_occurrence_details() {
  $.get('/models/classdefs/occurrences/' + occurrence_id + '/details', function(resp) { 
    data['occurrence'] = resp; 
    reservation_form.set_occurrence(data['occurrence']);
    get_calendar_events(data['occurrence'].starttime.substring(0,10));
    data.lesson = data.occurrence.classdef_id==188;
  }, 'json'); 
}

function change_teacher(staff_id) {
  payload = { "starttime": data.occurrence.starttime, "classdef_id": data.occurrence.classdef_id, "location_id": data.occurrence.location.id, "staff_id": staff_id };
  $.post('/models/classdefs/occurrences/' + data.occurrence.id, payload, function(resp) { data.occurrence = resp; }, 'json' );
}

function change_location(loc_id) {
  payload = { "starttime": data.occurrence.starttime, "classdef_id": data.occurrence.classdef_id, "location_id": loc_id, "staff_id": data.occurrence.staff_id };
  $.post('/models/classdefs/occurrences/' + data.occurrence.id, payload, function(resp) { data.occurrence = resp; }, 'json' );
}

function change_starttime(starttime) {
  payload = { "starttime": starttime, "classdef_id": data.occurrence.classdef_id, "location_id": data.occurrence.location.id, "staff_id": data.occurrence.staff_id };
  $.post('/models/classdefs/occurrences/' + data.occurrence.id, payload, function(resp) { data.occurrence = resp; alert("Start Time Changed") }, 'json' );
}

function change_capacity(new_capacity) {
  payload = { }
} 
