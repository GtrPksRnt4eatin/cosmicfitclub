data = {
  ticket: {},
  sessions: []
}

ctrl = {

  add_pass: function(e,m) {
    if( confirm(`add ${m.sess.name} to ticket?`) ) {
      var payload = { ticket_id: data.ticket.id, customer_id: data.ticket.customer.id, session_id: m.sess.id }
      $.post('/models/events/passes')
       .done( get_ticket )
    }
  },

  remove_pass: function(e,m) {
    $.del('/models/events/passes/' + m.pass.id)
     .done(get_ticket)
  },

  pass_checkin: function(e,m) {
    $.post('/models/events/passes/' + m.pass.id + '/checkin' )
     .done(get_ticket)
  },

  pass_checkout: function(e,m) {
    $.post('/models/events/passes/' + m.pass.id + '/checkout' )
     .done(get_ticket)
  },

  edit_pass_recipient: function(e,m) {
    custy_selector.show_modal(m.pass.customer.id, function(custy_id) {
      $.post('/models/events/passes/' + m.pass.id + '/transfer', { customer_id: custy_id } )
       .done(get_ticket)
    } );
  }

}

$(document).ready(function() {
  
  popupmenu      = new PopupMenu(id('popupmenu_container'));
  custy_selector = new CustySelector();

  custy_selector.ev_sub('show'       , popupmenu.show );
  custy_selector.ev_sub('close_modal', popupmenu.hide );

  include_rivets_select();
  include_rivets_dates();
  include_rivets_money();
  initialize_rivets();

  get_ticket();

})

function initialize_rivets() {
  rivets.formatters.stripe = function(val) { return 'https://manage.stripe.com/payments/' + val; }
  rivets.bind( document.body, { data: data, ctrl: ctrl } );
}

function get_ticket() {
  var ticket_id = getUrlParameter('id') ? getUrlParameter('id') : 0;
  $.get('/models/events/tickets/' + ticket_id )
   .success( function(tic) { data['ticket'] = tic; $('#json-viewer').jsonViewer(data['ticket']); get_sessions(); } )
   .fail   ( function()    { alert("failed to get ticket data"); } )
}

function get_sessions() {
  $.get('/models/events/' + data['ticket']['event']['id'] + '/sessions')
   .success( function(lst) { data['sessions'] = lst; } )
   .fail   ( function()    { alert("failed to get session list") } )
}