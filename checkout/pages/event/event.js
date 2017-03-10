/////////////////////////////////////// INITIALIZATION //////////////////////////////////////////////////

var STRIPE_HANDLER;

var data = {
  selected_price: {},
  one_session: false,
  one_price: false,
  free_event: false

}

$(document).ready( function() {

  initialize_stripe();
  initialize_rivets();
  set_event_listeners();
  set_first_price();
  choose_mode();

});

function initialize_stripe() {

  STRIPE_HANDLER = StripeCheckout.configure({
    zipCode:        true,
    locale:         'auto',
    billingAddress: true,
    key:            STRIPE_PUBLIC_KEY,
    token:          on_token_received
  });

}

function initialize_rivets() {

  include_rivets_dates();
  include_rivets_money();
  rivets.formatters.multiple = function(val)      { return val.length > 1; }
  rivets.formatters.empty    = function(val)      { return empty(val);     }
  rivets.formatters.equals   = function(val,val2) { return val== val2;     }
  rivets.bind( $('body'), { event: EVENT, customer: CUSTOMER, data: data, ctrl: ctrl } );  

}

function choose_mode() {
  data.one_session = EVENT.sessions.length == 1;
  data.one_price   = EVENT.prices.length   == 1;
  data.free_event  = EVENT.prices[0].full_price == 0;

}

function set_first_price() {
  clear_selected_price();
  EVENT.prices[0].selected = true;
  data.selected_price = EVENT.prices[0];
  set_included_sessions(EVENT.prices[0].included_sessions);
}

/////////////////////////////////////// INITIALIZATION //////////////////////////////////////////////////


///////////////////////////////////////// PAGE EVENTS ///////////////////////////////////////////////////

function set_event_listeners() {

  id('checkout').addEventListener('click', checkout );

}



var ctrl = {
  choose_price(e,m) {
    clear_selected_price();
    m.price.selected = true;
    data.selected_price = m.price;
    set_included_sessions(m.price.included_sessions);
  }
}

function clear_selected_price() {
  for(var i=0; i<EVENT.prices.length; i++)   { EVENT.prices[i].selected = false; }
}

function set_included_sessions(sessions) {
  for(var i=0; i<EVENT.sessions.length; i++) { 
    EVENT.sessions[i].selected = sessions.includes(EVENT.sessions[i].id); 
  }
}

////////////////////////////////////////// PAGE EVENTS ///////////////////////////////////////////////////


///////////////////////////////////////// STRIPE EVENTS //////////////////////////////////////////////////

function checkout() {

  STRIPE_HANDLER.open({
    name: 'Cosmic Fit Club',
    description: PLAN['name'],
    image: 'https://cosmicfit.herokuapp.com/background-blu.jpg',
    amount: EVENT['price']
  });

}

function on_token_received(token) {

  body = JSON.stringify({ 
    "type":  "event", 
    "plan_id": EVENT['id'], 
    "token": token 
  })

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