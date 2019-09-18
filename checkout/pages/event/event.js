/////////////////////////////////////// INITIALIZATION //////////////////////////////////////////////////

var STRIPE_HANDLER;

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
  customer_info: {};
  customer_status: {};
}

$(document).ready( function() {
  userview = new UserView();

  userview.ev_sub('on_user', function(id) {
    data.customer_info = userview.user;
    $.get('/models/customers/' + id + '/status', function(val) { data.customer_status = val; } )
  });

  initialize_stripe();
  initialize_rivets();
  get_event_data();
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
  rivets.formatters.multiple  = function(val)      { return empty(val) ? false : val.length > 1;   }
  rivets.formatters.empty     = function(val)      { return empty(val) || val=='';                 }
  rivets.formatters.equals    = function(val,val2) { return val== val2;                            }
  rivets.formatters.is_member = function(val)      { return empty(val) ? false : !empty(val.plan); } 

  rivets.bind( $('body'), { customer: CUSTOMER, data: data, ctrl: ctrl } );  

}

function get_event_data() {
  $.get('/models/events/' + EVENT_ID)
   .success( function(val) { data.event_data = val; set_event_mode(); set_first_price(); } )
   .fail( function() { alert("Failed to get Event"); } )
}

/////////////////////////////////////// INITIALIZATION //////////////////////////////////////////////////

///////////////////////////////////////// DERIVATIONS ///////////////////////////////////////////////////

function set_event_mode() {
  
  if( data.event_data.registration_url          ) { data.mode = 'external';   return; }
  if( data.event_data.a_la_carte                ) { data.mode = 'a_la_carte'; return; }
  if( data.event_data.prices.length>1           ) { data.mode = 'multi';      return; }
  if( free_event()                    ) { data.mode = 'free';       return; }
  if( data.event_data.prices[0].member_price==0 ) { data.mode = 'memberfree'; return; }
  if( data.event_data.prices.length == 1        ) { data.mode = 'single';     return; }

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
      data.total_price = ( member() ? data.event_data.prices[0].member_price : data.event_data.prices[0].full_price ); 
      break;

    case 'multi':
      data.total_price = ( member() ? data.selected_price.member_price : data.selected_price.full_price );
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

    default: 
      alert('mode not set!');
      break;

  }

}

function calculate_custom_prices() {
  
  if(data.mode!='a_la_carte') { return; }
  data.custom_full_price = 0;
  data.custom_member_price = 0;
  for(var i=0; i<data.included_sessions.length; i++) {
    sess = data.event_data.sessions.find( function(x) { return x.id == data.included_sessions[i]; } );
    data.custom_full_price += sess.individual_price_full;
    data.custom_member_price += sess.individual_price_member;
  } 

}

function set_included_sessions(sessions) {
  for(var i=0; i<data.event_data.sessions.length; i++) { 
    data.event_data.sessions[i].selected = sessions.indexOf(data.event_data.sessions[i].id)!=-1;
  }
  data.included_sessions = sessions.slice(0);
}

function toggle_included_session(session) {
  sessions = data.included_sessions;
  var i = sessions.indexOf(session.id);
  if(i==-1) { sessions.push(session.id); }
  else      { sessions.splice(i, 1); }
  set_included_sessions(sessions);

}

function clear_selected_price() {
  for(var i=0; i<data.event_data.prices.length; i++)   { data.event_data.prices[i].selected = false; }
}

function free_event() { return data.event_data.prices[0].member_price==0 && data.event_data.prices[0].full_price==0 }

function signed_in()  { return !empty(CUSTOMER); }
function member()     { return signed_in() ? !empty(CUSTOMER.plan) : false; }

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
  tog_session(e,m) {
    if( data.mode !== 'a_la_carte' ) return;
    data.a_la_carte = true;
    clear_selected_price();
    toggle_included_session(m.sess);
    calculate_custom_prices();
    calculate_total();    
  }
}

////////////////////////////////////////// PAGE EVENTS ///////////////////////////////////////////////////


///////////////////////////////////////// STRIPE EVENTS //////////////////////////////////////////////////

function checkout() {

  calculate_total()
  
  if(data.total_price==0) { register(); return; }

  STRIPE_HANDLER.open({
    name: 'Cosmic Fit Club',
    description: data.event_data['title'],
    image: 'https://cosmicfit.herokuapp.com/background-blu.jpg',
    amount: data.total_price
  });

}

function register() {

  body = JSON.stringify({
    "event_id": data.event_data['id'],
    "included_sessions": data.included_sessions,
    "email": signed_in() ? CUSTOMER.email : id('email').value
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