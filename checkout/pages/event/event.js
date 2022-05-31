/////////////////////////////////////// INITIALIZATION //////////////////////////////////////////////////

var STRIPE_HANDLER;
var daypilot;

var data = {
  selected_price: {},
  one_session: false,
  one_price: false,
  free_event: false,
  total_price: 0,
  included_sessions: [],
  mode: '',
  a_la_carte: '',
  custom_full_price: '',
  custom_member_price: '',
  event_data: {},
  customer_info: null,
  customer_status: null,
  multiplier: 1,
  selected_timeslot: {
    starttime: null,
    endtime: null,
    duration_min: 60
  },
  rental: {
    starttime: '',
    endtime: '',
    activity: '',
    note: '',
    slots: []
  },
  num_slots: 1,
  attendance: [],
  selected_session: null
}

$(document).ready( function() {

  initialize_stripe();
  view = initialize_rivets();

  userview       = new UserView( id('userview_container') );
  popupmenu      = new PopupMenu( id('popupmenu_container') );
  custy_selector = new CustySelector();
  pay_form       = new PaymentForm();

  custy_selector.ev_sub('show'       , popupmenu.show );
  custy_selector.ev_sub('close_modal', popupmenu.hide );
  custy_selector.show_add_form();

  pay_form.customer_facing();
  pay_form.ev_sub('show', popupmenu.show );
  pay_form.ev_sub('hide', popupmenu.hide );
  //popupmenu.ev_sub('close', pay_form.stop_listen_cardswipe);

  userview.ev_sub('on_user', function(custy) {
    if(custy==null) { data.customer_info = null; data.customer_status = null; return; }
    data.customer_info = custy;
    $.get('/models/customers/' + custy.id + '/status', function(val) { data.customer_status = val; calculate_total(); } )
  });

  get_event_data();

  session_chooser = get_element(view,'session-chooser');
  private_slots   = get_element(view,'private-slots');
  
  session_chooser && session_chooser.ev_sub('on_session_selected', function(session) { data.selected_session = session; } );
  
});

function initialize_stripe() {

  STRIPE_HANDLER = StripeCheckout.configure({
    locale:         'auto',
    key:            STRIPE_PUBLIC_KEY,
    token:          on_token_received
  });

}

function initialize_rivets() {

  include_rivets_dates();
  include_rivets_money();
  rivets.formatters.multiple   = function(val)         { return empty(val) ? false : val.length > 1;   }
  rivets.formatters.empty      = function(val)         { return empty(val) || val=='';                 }
  rivets.formatters.sess_empty = function(val)         { return val.length == 0;                       }
  rivets.formatters.equals     = function(val,val2)    { return val== val2;                            }
  rivets.formatters.is_member  = function(val)         { return empty(val) ? false : !empty(val.plan); } 
  rivets.formatters.num_tix    = function(val)         { return ( val && val > 1 ) ? val + ' Tickets ' : ''; }
  rivets.formatters.first_price_title = function(val) { return ( val && val[0] ) ? val[0].title : ""; }
  rivets.formatters.diff_days  = function(val,val2)    { return !moment(val).isSame(moment(val2), 'date'); }
  rivets.formatters.fix_index  = function(val, arg)    { return val + 1; }
  rivets.formatters.populate_sess = function(val)     { return val.map( function(x) { return data.event_data.sessions.find( function (y) { return y.id == x } ) } );};

  return rivets.bind( $('body'), { customer: CUSTOMER, data: data, ctrl: ctrl } );  

}

function get_event_data() {
  $.get('/models/events/' + EVENT_ID)
   .success( on_event_data )
   .fail( function() { alert("Failed to get Event"); } )
}

function on_event_data(val) {
  data.event_data = val;
  session_chooser && session_chooser.build_daypilot();
  session_chooser && session_chooser.load_sessions();
  get_attendance();
  set_event_mode(); 
  set_first_price();
  if(data.mode == 'privates')
    setup_daypilot();
}

function get_attendance() {
  $.get("/models/events/" + data.event_data.id + "/attendance2")
   .success( function(val) { 
     data.attendance = val;
     session_chooser && session_chooser.update_daypilot_colors();
   });
}

/////////////////////////////////////// INITIALIZATION //////////////////////////////////////////////////

///////////////////////////////////////// DERIVATIONS ///////////////////////////////////////////////////

function set_event_mode() {
  if( data.event_data.mode                      ) { data.mode = data.event_data.mode; return; }                  
  if( data.event_data.registration_url          ) { data.mode = 'external';   return; }
  if( data.event_data.a_la_carte                ) { data.mode = 'a_la_carte'; return; }
  if( data.event_data.prices.length>1           ) { data.mode = 'multi';      return; }
  if( free_event()                              ) { data.mode = 'free';       return; }
  if( data.event_data.prices[0].member_price==0 ) { data.mode = 'memberfree'; return; }
  if( data.event_data.prices.length == 1        ) { data.mode = 'single';     return; }
}

function setup_daypilot() {
  daypilot = new DayPilot.Calendar('daypilot', {
    viewType:                  "Days",
    days:                      moment(data.event_data.endtime).diff(moment(data.event_data.starttime),'days')+1,
    startDate:                 moment(data.event_data.starttime).format("YYYY-MM-DD"),
    headerDateFormat:          "ddd MMM d",
    cellDuration:              30,
    cellHeight:                20,
    businessBeginsHour:        10,
    businessEndsHour:          20,
    dayBeginsHour:             10,
    dayEndsHour:               20,
    timeRangeSelectedHandling: "Disabled",  
    eventDeleteHandling:       "Disabled",
    eventMoveHandling:         "Disabled",
    eventResizeHandling:       "Disabled",
    eventHoverHandling:        "Disabled",
    eventClickHandling:        'Select',
    onTimeRangeSelected:       on_timeslot_selected,
    onEventClick:              on_session_selected
  });
  
  data.event_data.sessions.for_each( function(x) {
    daypilot.events.add({ id: x.id, start: moment(x.start_time).subtract(4,'hours').format(), end: moment(x.end_time).subtract(4,'hours').format(), text: x.title + "\r\n" + rivets.formatters.money(x.individual_price_full) });  
  });

  $.get("/models/events/" + data.event_data.id + "/attendance2")
   .success( function(val) { 
    data.attendance = val;
    session_chooser && session_chooser.load_sessions();
    update_daypilot_colors();
  })

  $.get("/models/groups/range/2021-07-22/2021-07-25")
   .success( function(val) {
    for(i=0; i<val.length; i++) {
      daypilot.events.add(val[i]);
    }
  })

  daypilot.init();
}

function on_timeslot_selected(args) {
  if(!userview.logged_in) { userview.onboard(); return;  }
  data.selected_timeslot.starttime = new Date(args.start.value);
  data.selected_timeslot.endtime = new Date(data.selected_timeslot.starttime.getTime() + 60 * 60 * 1000)
  data.num_slots = 2;
  data.rental.slots = [];
  data.rental.slots.push( { customer_id: userview.id, customer_string: userview.custy_string } );
  data.rental.slots.push( { customer_id: 0, customer_string: "Add Student" } );
  calculate_total();
}

function on_session_selected(args) {
  if(args.originalEvent.type=='touchend') { return; }
  if(!userview.logged_in) { userview.onboard(); return;  }
  if( !session_available(args.e.data.id) ) { return; }

  data.a_la_carte = true;
  clear_selected_price();
  toggle_included_session(args.e.data);
  calculate_custom_prices();
  calculate_total();
  update_daypilot_colors();
}

function session_available(id) {
  let session = data.event_data.sessions.find( function(y) { return id == y.id} );
  let attendance = data.attendance.find( function(z) { return id == z.id; } );
  if( !attendance || !session ) return false;
  if( attendance.passes.length >= session.max_capacity || ( session.title == "Private" && attendance.passes.length > 0 ) ) return false;
  return true;
}

function update_daypilot_colors() {
  daypilot.events.all().for_each( function(x) {
    let session = data.event_data.sessions.find( function(y) { return x.id() == y.id} );
    let attendance = data.attendance.find( function(z) { return x.id() == z.id; } );
    if( !attendance || !session ) return;
    if(session.title != "Private") {
      x.text(session.title + "\r\n" + rivets.formatters.money(session.individual_price_full) + "\r\n" + attendance.passes.length + "/" + session.max_capacity);
    }
    if(attendance.passes.length >= session.max_capacity || ( session.title == "Private" && attendance.passes.length > 0 ) ) {
      x.client.backColor("#AAAAAA");
    }
    else if( data.included_sessions.includes(x.id()) ) {
      x.client.backColor("#CCCCFF");
    }
    else {
      x.client.backColor("#FFFFFF");
    }
    daypilot.events.update(x);
  });
}

function set_first_price() {
  clear_selected_price();
  if(empty(data.event_data.prices[0])) return;
  data.event_data.prices[0].selected = true;
  data.selected_price = data.event_data.prices[0];
  set_included_sessions(data.event_data.prices[0].included_sessions);
  calculate_total();

}

function calculate_total() {

  switch(data.mode) {

    case 'free': 
      data.total_price = 0;
      break;

    case 'memberfree':
    case 'single':
      data.total_price = ( member() ? data.event_data.prices[0].member_price : data.event_data.prices[0].full_price ) * data.multiplier; 
      break;

    case 'multi':
      data.total_price = ( member() ? data.selected_price.member_price : data.selected_price.full_price ) * data.multiplier; 
      break;

    case 'a_la_carte':
      $('#sessions_list tr').addClass('selectable');
      if( data.a_la_carte ) {
        data.total_price = ( member() ? data.custom_member_price : data.custom_full_price );
      }
      else { 
        data.total_price = ( member() ? data.selected_price.member_price : data.selected_price.full_price );
      }
      break;

    case 'external':
      break;
  
    case 'privates':
      data.total_price = data.custom_full_price;

      if(!data.selected_timeslot.starttime) break; 

      switch(data.num_slots) {
        case 1: data.total_price = 9200;  break;
        case 2: data.total_price = 12400; break;
      }
      break;

    default: 
      //alert('mode not set!');
      break;

  }

}

function calculate_custom_prices() {

  if(data.mode!='a_la_carte' && data.mode!='privates') { return; }
  data.custom_full_price = 0;
  data.custom_member_price = 0;
  for(var i=0; i<data.included_sessions.length; i++) {
    sess = data.event_data.sessions.find( function(x) { return x.id == data.included_sessions[i]; } );
    data.custom_full_price += sess.individual_price_full;
    data.custom_member_price += sess.individual_price_member;
  } 

}

function sort_included_sessions() {
  data.included_sessions.sort( function(a,b) { 
    let sess_a = data.event_data.sessions.find( function(x) { return x.id == a; } );
    let sess_b = data.event_data.sessions.find( function(x) { return x.id == b; } );
    if(!sess_a) { return sess_b ? 1 : 0; }
    if(!sess_b) { return sess_a ? -1 : 0; }
    return moment(sess_a.start_time) - moment(sess_b.start_time);
  });
}

function set_included_sessions(sessions) {
  for(var i=0; i<data.event_data.sessions.length; i++) { 
    data.event_data.sessions[i].selected = sessions.indexOf(data.event_data.sessions[i].id)!=-1;
  }
  data.included_sessions = sessions.slice(0);
  sort_included_sessions();
}

function toggle_included_session(session) {
  sessions = data.included_sessions;
  var i = sessions.indexOf(session.id);
  if(i==-1) { sessions.push(session.id); }
  else { 
    if(sessions.length == 1) { sessions = []; }
    else { sessions.splice(i, 1); }
  }
  set_included_sessions(sessions);
}

function clear_selected_price() {
  for(var i=0; i<data.event_data.prices.length; i++)   { data.event_data.prices[i].selected = false; }
}

function free_event() { return data.event_data.prices[0].member_price==0 && data.event_data.prices[0].full_price==0 }

function signed_in()  { return !empty(data.customer_info) }
function member()     { 
  if( empty(data.customer_status) ) { return false; }
  return signed_in() ? data.customer_status.membership.id != 0 : false; 
}

///////////////////////////////////////// DERIVATIONS ///////////////////////////////////////////////////

///////////////////////////////////////// PAGE EVENTS ///////////////////////////////////////////////////

var ctrl = {
  choose_price(e,m) {
    data.a_la_carte = false;
    clear_selected_price();
    m.price.selected = true;
    data.selected_price = m.price;
    set_included_sessions(m.price.included_sessions);
    calculate_total();
  },
  checkout(e,m) {
    checkout();
  },
  checkout_new(e,m) {
    checkout_new();
  },
  tog_session(e,m) {
    if( data.mode !== 'a_la_carte' ) return;
    data.a_la_carte = true;
    clear_selected_price();
    toggle_included_session(m.sess);
    calculate_custom_prices();
    calculate_total();    
  },
  set_multiplier(e,m) {
    data.multiplier = parseInt(e.target.value);
    calculate_total()
  },
  set_num_slots: function(e,m) {
    data.num_slots = parseInt(e.target.value);
    data.num_slots = isNaN(data.num_slots) ? 0 : data.num_slots;
    while(data.rental.slots.length<data.num_slots) {
      data.rental.slots.push({ customer_id: 0, customer_string: 'Add Student' }); 
    }
    while(data.rental.slots.length>data.num_slots){
      data.rental.slots.pop();
    }
    calculate_total();
  },
  choose_custy: function(e,m) {
    custy_selector.show_modal(m.slot.customer_id, function(custy_id) {
      m.slot.customer_id = custy_id;
      m.slot.customer_string = custy_selector.selected_customer.list_string;
    } );
  },
  clear_timeslot: function(e,m) {
    data.selected_timeslot.starttime = null;
  }
}

////////////////////////////////////////// PAGE EVENTS ///////////////////////////////////////////////////


///////////////////////////////////////// STRIPE EVENTS //////////////////////////////////////////////////

function checkout_new() {
  calculate_total();

  let desc = data.event_data.name;

  pay_form.checkout(userview.id, data.total_price, desc ,null, function(payment_id) {

    var payload = {
      customer_id:       userview.id, 
      event_id:          data.event_data['id'],
      included_sessions: data.included_sessions,
      total_price:       data.total_price,
      payment_id:        payment_id,
      price_id:          null
    }
     
    $.post('precharged', payload)
     .done( on_successful_charge )
     .fail( on_failed_charge )

  });
}

function checkout() {

  calculate_total()
  
  if(data.total_price==0) { register(); return; }

  STRIPE_HANDLER.open({
    name: 'Cosmic Fit Club',
    description: data.event_data.name + ( data.multiplier > 1 ? ' (x' + data.multiplier + ')' : "" ),
    image: 'https://cosmicfit.herokuapp.com/background-blu.jpg',
    amount: data.total_price
  });

}

function register() {
  if( data.mode == 'a_la_carte' ) {
    if(data.included_sessions==[]) { alert("Select the sessions which you will be attending!"); return; }
  }

  body = JSON.stringify({
    "event_id": data.event_data['id'],
    "included_sessions": data.included_sessions,
    "email": signed_in() ? data.customer_info.email : id('email').value
  });

  $.post('register', body )
   .done( on_successful_charge )
   .fail( on_failed_charge     );

}

function on_token_received(token) {

  body = JSON.stringify({ 
    "type":  "event", 
    "event_id": data.event_data['id'], 
    "total_price": data.total_price,
    "included_sessions": data.included_sessions,
    "multiplier": data.multiplier,
    "metadata": {
      "event_id": data.event_data['id'], 
      "included_sessions": data.included_sessions.join(','),
      "selected_price": empty(data.selected_price) ? 0 : data.selected_price.id
    },
    "token": token,
    "selected_price": data.selected_price
  });

  $.post( 'charge', body )
   .done( on_successful_charge )
   .fail( on_failed_charge     );

}

function on_successful_charge(e) { 
  window.location.href = '/checkout/complete'; 
}

function on_failed_charge(e) {
  switch (e.status) {
    case 400: 
      alert('There was an error processing the payment. Your Card Has not been charged.'); 
      break;

    case 409: 
      alert('Your Card Has not Been Charged. You already have a Membership, Sign in to Modify it.'); 
      window.location.href = '/login'; 
      break;

    case 500: 
      alert('An Error Occurred!'); 
      break;

    default: 
      alert('huh???'); 
      break;
  }
} 

///////////////////////////////////////// STRIPE EVENTS //////////////////////////////////////////////////