data = {
  event_list: [],
  customers: [],
  customer: {
    id: 0,
    payments: [],
    payment_sources: [],
    class_passes: [],
    membership_status: null,
    waiver: null,
    event_history: null
  },
  customer_info: {
    name: "",
    email: "",
    phone: "",
    address: ""
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
  package_id: 0,
  package_price: 0,
  transfer_to: 0,
  transfer_from: 0,
  transfer_to_amount: 0,
  transfer_from_amount: 0,
  num_comp_tix: 0,
  comp_reason: "Reason for Comps",
  misc_charge: {
    amount: 0,
    reason: ""
  },
  child_id: 0
}

ctrl = {

  add_child: function(e,m) {
    $.post("/models/customers/" + data.customer.id + "/add_child", { child_id: parseInt($('#children').val()) }, function() { alert("Child Added"); refresh_customer_data(); })
  },

  give_comps: function(e,m) {
    $.post(`/models/customers/${data.customer.id}/add_passes`, { value: data.num_comp_tix, reason: data.comp_reason }, function() { alert("Passes Added!"); refresh_customer_data(); })
  },

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
  },

  comp: function(e,m) {
    $.post('/models/passes/compticket', { "customer_id": data.customer.id })
    .done( function(e) { refresh_customer_data(); } )
    .fail( function(e) { alert('failed'); });
  },

  buy_package: function(e,m) {
    var package_id = $('#packages option:selected').val();
    var package_name = $('#packages option:selected').data("name");
    var package_price = $('#packages option:selected').data("price");
    payment_form.checkout( data.customer.id, package_price, package_name, null, function(payment_id) {
      $.post('/checkout/pack/buy', { customer_id: data.customer.id, pack_id: package_id , payment_id: payment_id })
       .success( function() { alert('Purchase Successful'); refresh_pass_data(); } )
       .fail( function(xhr, textStatus, errorThrown) { alert(xhr.responseText); } );
    });
  },

  update_customer_info: function(e,m) {
    $.post('/models/customers/' + data.customer.id + '/info', JSON.stringify(data.customer_info));
  },

  get_send_custy: function(e,m) {
    custy_modal.show_modal( data.transfer_to, function(val) { data.transfer_to = val; })
  },

  get_recv_custy: function(e,m) {
    custy_modal.show_modal( data.transfer_from, function(val) { data.transfer_from = val; })
  },

  get_share_custy: function(e,m) {
    custy_modal.show_modal( data.customer.wallet.shared_with, function(val) {
      if(!confirm("Link These Customers Wallets Permanently?")) { return; } 
      $.post('/models/customers/' + data.customer.id + '/add_partner', { partner_id: val })
       .success( function() { alert('Wallets Linked'); refresh_customer_data(); } )
       .fail( function(xhr, textStatus, errorThrown) { alert(xhr.responseText); });
    })
  },

  send_passes: function(e,m) {
    $.post('/models/customers/' + data.customer.id + '/transfer', { from: data.customer.id, to: data.transfer_to, amount: data.transfer_to_amount } )
     .success( function(e) { alert('Transfer Complete'); refresh_customer_data(); } )
     .fail( function(e) { alert('Transfer Failed') });
  },

  receive_passes: function(e,m) {
    $.post('/models/customers/' + data.customer.id + '/transfer', { from: data.transfer_from, to: data.customer.id, amount: data.transfer_from_amount } )
     .success( function(e) { alert('Transfer Complete'); refresh_customer_data(); } )
     .fail( function(e) { alert('Transfer Failed') });
  },

  undo_transaction: function(e,m) {
    if(confirm("Really Undo Transation?")) {
      $.del('/models/passes/transactions/' + m.trans.id)
       .fail( function() { alert("Failed to undo transaction") })
       .done( function() { refresh_customer_data(); })
    }
  },

  event_selected: function(e,m) {
    tic_selector.load_event(e.target.value);
  },

  prepaid_month: function(e,m) {
    payment_form.checkout(
      data.customer.id, 
      16000, 
      "Prepaid Monthly Subscription", 
      { "customer_id": data.customer.id }, 
      function(payment_id) {
        $.post('/models/memberships/prepaid', {
          customer_id: data.customer.id, 
          plan_id:     16,
          payment_id:  payment_id
        })
        .done( function(e) { refresh_customer_data(); } )
        .fail( function(e) { alert('subscription failed!'); }); 
      }
    )
  },

  misc_charge: function(e,m) {
    payment_form.checkout(
      data.customer.id,
      data.misc_charge.amount,
      data.misc_charge.reason,
      { "customer_id": data.customer_id },
      function(payment_id) { 
        $.post('/models/customers/misc_payment', { payment_id: payment_id });
        get_customer_payments(); 
      }
    )
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

  userview       = new UserView(  id('userview_container')  );
  popupmenu      = new PopupMenu( id('popupmenu_container') );
  custy_selector = new CustySelector( id('custy_select_container'), false, false, false, true);
  custy_modal    = new CustySelector( null, true, true, false, false ); 
  payment_form   = new PaymentForm();

  custy_modal.ev_sub('show', popupmenu.show );
  custy_modal.ev_sub('close_modal', popupmenu.hide );
  payment_form.ev_sub('show', popupmenu.show );
  payment_form.ev_sub('hide', popupmenu.hide );
  popupmenu.ev_sub('close', payment_form.stop_listen_cardswipe);
  custy_selector.ev_sub('customer_selected', on_custy_selected );

  tic_selector = new TicketSelector( id('ticketselector_container') );
  tic_selector.ev_sub('paynow', function(args) {
    var custy = data.customer;
    if(!custy) { alert('No Customer Selected!'); return; } 
    payment_form.checkout(args[0], args[1], args[2], args[3], args[4]) 
  });

  tic_selector.ev_sub('ticket_created', refresh_customer_data);

  $.get('/models/customers', on_custylist, 'json');

  $('#classes').chosen({ search_contains: true });
  $('#staff').chosen({ search_contains: true });
  $('#children').chosen({ search_contains: true });

  $('#packages').on('change', on_package_selected );

  $('ul.tabs li').click(function(){
    var tab_id = $(this).attr('data-tab');

    $('ul.tabs li').removeClass('current');
    $('.tab-content').removeClass('current');

    $(this).addClass('current');
    $("#"+tab_id).addClass('current');
  });

  var customer_id = getUrlParameter('id') ? getUrlParameter('id') : 0;
  if( ! empty(customer_id) ) { choose_customer(customer_id); custy_selector.select_customer(customer_id, true); }  
  history.replaceState({ "id": customer_id }, "", `customer_file?id=${customer_id}`);

  $(window).bind('popstate', function(e) { 
    choose_customer(history.state.id);
    custy_selector.select_customer(history.state.id, true);
  });

  $('#comp_reason').on('focus', function(e) { if(e.target.value == "Reason for Comps") { e.target.value = ""; } } )
  $('#comp_reason').on('blur', function(e) { if(e.target.value == "") { e.target.value = "Reason for Comps"; } } )

  $.get('/models/events', function(resp) { data.event_list = resp; init_event_selector(); }, 'json');

});

function setupBindings() {
  include_rivets_money();
  include_rivets_dates();
  include_rivets_select();

  rivets.formatters.count               = function(val) { return empty(val) ? 0     : val.length;                           }
  rivets.formatters.zero_if_null        = function(val) { return empty(val) ? 0     : val;                                  }
  rivets.formatters.has_membership      = function(val) { return empty(val) ? false : ( val.name != 'None' );               }
  rivets.formatters.custy_file          = function(val) { return empty(val) ? '#'   : '/frontdesk/customer_file?id=' + val; }
  rivets.formatters.subscription_link   = function(val) { return empty(val) ? '#'   : '/admin/subscription?id=' + val;      }
  rivets.formatters.remove_invalid      = function(val) { return val == "Invalid date" ? '' : val; }
  rivets.formatters.waiver_img          = function(val) { return '/models/customers/' + val + '/waiver.svg'; }
  rivets.formatters.href_stripe_details = function(val) { return '/admin/payment_sources?id=' + val; }
  rivets.formatters.href_stripe_payment = function(val) { return 'https://dashboard.stripe.com/payments/' + val; }
  rivets.formatters.custy_list_string   = function(val) { return CustySelector.get_list_string(val, "Select a Customer");   }
  rivets.formatters.ticket_url          = function(val) { return "/admin/edit_ticket?id=" + val; }

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

function on_custy_selected(custy_id) {
  if(custy_id==0) return;
  history.pushState({ "id": custy_id }, "", `customer_file?id=${custy_id}`); 
  choose_customer(custy_id); 
}

function on_package_selected(e) {
  data.package_price = $('#packages option:selected').data("price");
}

function choose_customer(id) {
  resetCustomer();
  data.reservation.customer_id = id;
  data.customer.id = parseInt(id);
  tic_selector.load_customer(id);
  refresh_customer_data();
}

function clear_reservations() {
  data.reservation.classdef_id=0;
  data.reservation.staff_id=0;
  data.reservation.starttime=null;
}

function refresh_customer_data() {
  if(data.customer.id === undefined) return;
  $.get(`/models/customers/${data.customer.id}`,                  function(resp) { data.customer_info              = resp; }, 'json');
  $.get(`/models/customers/${data.customer.id}/payment_sources`,  function(resp) { data.customer.payment_sources   = resp; }, 'json');
  $.get(`/models/customers/${data.customer.id}/membership`,       function(resp) { data.customer.membership_status = resp; }, 'json');
  $.get(`/models/customers/${data.customer.id}/event_history`,    function(resp) { data.customer.event_history     = resp; }, 'json');
  $.get(`/models/customers/${data.customer.id}/family`,           function(resp) { data.customer.family            = resp; }, 'json');
  $.get(`/models/customers/${data.customer.id}/subscriptions`,    function(resp) { data.customer.subscriptions     = resp; }, 'json');
  $.get(`/models/customers/${data.customer.id}/upcoming_rentals`, function(resp) { data.customer.rentals           = resp; }, 'json');
  refresh_pass_data();
  get_customer_payments();
  refresh_reservations();
}

function refresh_pass_data() {
  $.get(`/models/customers/${data.customer.id}/class_passes`,    function(resp) { data.customer.class_passes      = resp; }, 'json');
  $.get(`/models/customers/${data.customer.id}/wallet`,          function(resp) { data.customer.wallet            = resp; }, 'json');
}

function get_customer_payments() {
  $.get(`/models/customers/${data.customer.id}/payments`,        function(resp) { data.customer.payments          = resp; }, 'json');
}

function refresh_reservations() { 
  $.get(`/models/customers/${data.customer.id}/reservations`, function(resp) { data.customer.reservations = resp; }, 'json'); 
}

function resetCustomer() {
  data.customer_info = {};
  data.customer.payment_sources = [];
  data.customer.class_passes = [];
  data.customer.membership_status = null;
  data.customer.wallet = null;
  data.customer.event_history = null;
}

function init_event_selector() {
  this.selectize_instance = $('.event_selector').selectize({
    options: data.event_list,
    valueField: 'id',
    labelField: 'name',
    searchField: 'name',
  })[0];
}
