data = {
  customer_id: 0,
  stripe_details: null
}

ctrl = {

  add_source: function(e,m) {
    savecardform.get_new_card();
  },

  remove_source: function(e,m) {
    $.post('/checkout/remove_card', { source_id: m.source.id, customer_id: data.customer_id } )
     .success( get_stripe_data )
     .fail( function() { alert( 'failed to remove card') } )
  },

  set_default: function(e,m) {
    $.post('/checkout/set_default_card', { source_id: m.source.id, customer_id: data.customer_id } )
     .success( get_stripe_data )
     .fail( function() { alert( 'failed to set default card') } )
  } 
}

$(document).ready(function() {
  
  savecardform     = new SaveCardForm()
  popupmenu        = new PopupMenu( id('popupmenu_container') );

  custy_selector   = new CustySelector( id('custyselector_container') );
  custy_selector.ev_sub('customer_selected', customer_selected );

  savecardform.ev_sub('show', popupmenu.show );
  savecardform.ev_sub('hide', popupmenu.hide );
  savecardform.ev_sub('card_saved', get_stripe_data);
  popupmenu.ev_sub('close', savecardform.stop_listen_cardswipe);

  rivets.formatters.stripe_custy_link        = function(val) { return 'https://dashboard.stripe.com/customers/' + val;     }
  rivets.formatters.stripe_payment_link      = function(val) { return 'https://dashboard.stripe.com/payments/' + val;      }
  rivets.formatters.stripe_subscription_link = function(val) { return 'https://dashboard.stripe.com/subscriptions/' + val; }
  rivets.formatters.default_source           = function(val) { return val === data.stripe_details.default_source;          }
  rivets.formatters.created_date             = function(val) { return new Date(val*1000).toDateString(); }

  rivets.bind( document.body, { data: data, ctrl: ctrl } );

  setup_history_api();

});

function setup_history_api() {
  var id = getUrlParameter('id') ? getUrlParameter('id') : 0;
  if( ! empty(id) ) { set_customer(id); }  
  $(window).bind('popstate', function(e) { set_customer(history.state.id) });
}

function customer_selected(id) {
  history.replaceState( { "id": id }, "", 'payment_sources?id=' + id );
  data.customer_id = custy_id; get_stripe_data(); 
}

function set_customer(id) {
  custy_selector.select_customer(id);
  savecardform.get_customer(id)
}

function get_stripe_data() {
  $.get('/models/customers/' + data.customer_id + '/stripe_details', 'json')
   .success( function(resp) { data.stripe_details = resp; } )
   .fail( function(resp) { data.stripe_details = null; } )
}