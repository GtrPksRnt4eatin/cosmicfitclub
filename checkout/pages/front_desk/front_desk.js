data = {
  customers: [],
  customer: {
    payment_sources: [],
    class_passes: [],
    membership_status: null
  },
  reservation: {
    customer_id: 0,
    classdef_id: 0,
    staff_id: 0,
    starttime: null,
  },
  amount: 0,
  starttime: null,
  reservation_errors: [],
  package_id: 0
}

ctrl = {

  reserve_class_pass: function(e,m) {
    if( !validate_reservation() ) return; 
    post_reservation("class_pass");
  },

  reserve_membership: function(e,m) {
    if( !validate_reservation() ) return;
    post_reservation("membership");
  },

  reserve_paynow: function(e,m) {
    if( !validate_reservation() ) { return; }
    classname = $('#classes option:selected').text()
    teachername = $('#staff option:selected').text()
    reason = `${classname} w/ ${teachername} - ${moment($('#timeslot')[0].value).format('ddd MMM D @ h:mm A')}`;
    payment_form.checkout( data.reservation.customer_id, 2500, reason, null, function(payment_id) {
      data.reservation.payment_id = payment_id;
      post_reservation("payment");
    });
  },

  reservation_checkin: function(e,m) {
    $.post(`/models/classdefs/reservation/${m.res.id}/checkin`)
     .done( )
  }

}

function post_reservation(type) {
  data.reservation.transaction_type = type;
  $.post('/models/classdefs/reservation', data.reservation)
   .done( function(e) { refresh_customer_data(); clear_reservations(); } )
   .fail( function(e) { alert('reservation failed!'); }); 
}

$(document).ready( function() {

  setupBindings();

  popupmenu = new PopupMenu( id('popupmenu_container') );
  payment_form = new PaymentForm();

  payment_form.ev_sub('show', popupmenu.show );
  payment_form.ev_sub('hide', popupmenu.hide );
  popupmenu.ev_sub('close', payment_form.stop_listen_cardswipe);

  $.get('/models/customers', on_custylist, 'json');

  $('#customers').chosen();
  $('#classes').chosen();
  $('#staff').chosen();

  $('#customers').on('change', on_customer_selected );

  $('ul.tabs li').click(function(){
    var tab_id = $(this).attr('data-tab');

    $('ul.tabs li').removeClass('current');
    $('.tab-content').removeClass('current');

    $(this).addClass('current');
    $("#"+tab_id).addClass('current');
  });

});

function setupBindings() {
  include_rivets_money();
  include_rivets_dates();
  include_rivets_select();

  rivets.formatters.count = function(val) { return empty(val) ? 0 : val.length; }
  rivets.formatters.zero_if_null = function(val) { return empty(val) ? 0 : val; }
  rivets.formatters.has_membership = function(val) { return( empty(val) ? false : val.name != 'None' ); }

  rivets.bind( $('body'), { data: data, ctrl: ctrl } );
}

function validate_reservation() {
  data.reservation_errors = [];
  if( ! data.reservation.customer_id ) { data.reservation_errors.push("You must select a Customer"); }
  if( ! data.reservation.classdef_id ) { data.reservation_errors.push("You must select a Class");    }
  if( ! data.reservation.staff_id    ) { data.reservation_errors.push("You must select a Teacher");  }
  if( ! data.reservation.starttime   ) { data.reservation_errors.push("You must select a Timeslot"); }
  if( data.reservation_errors.length == 0 ) return true;
  $('#class_checkin_table').shake();
  return false;
}

function on_custylist(list) {
  data.customers = list;
}

function on_customer_selected(e) {
  resetCustomer();
  data.reservation.customer_id = e.target.value;
  data.customer.id = parseInt(e.target.value);
  refresh_customer_data();
}

function clear_reservations() {
  data.reservation.classdef_id=0;
  data.reservation.staff_id=0;
  data.reservation.starttime=null;
}

function refresh_customer_data() {
  $.get(`/models/customers/${data.customer.id}/payment_sources`, function(resp) { data.customer.payment_sources   = resp; }, 'json');
  $.get(`/models/customers/${data.customer.id}/class_passes`,    function(resp) { data.customer.class_passes      = resp; }, 'json');
  $.get(`/models/customers/${data.customer.id}/status`,          function(resp) { data.customer.membership_status = resp; }, 'json');
  refresh_reservations()
}

function refresh_reservations() { $.get(`/models/customers/${data.customer.id}/reservations`, function(resp) { data.customer.reservations = resp; }, 'json'); }

function resetCustomer() {
  data.customer.payment_sources = [];
  data.customer.class_passes = [];
  data.customer.membership_status = null;
}