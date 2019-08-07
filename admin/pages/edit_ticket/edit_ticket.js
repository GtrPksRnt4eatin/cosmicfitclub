data = {

}

ctrl = {
  assign_recipient: function(e,m) {
    $.post('/models/events/tickets/' + data.ticket.id + '/assign_recipient', { recipient_id: data.recipient })
     .done(function() { location.reload() } )
     .fail( alert('Assigning Recipient Failed') )
  },

  split_ticket: function(e,m) {
    $.post('/models/events/tickets/' + data.ticket.id + '/split', { recipient_id: data.split_recipient, session_ids: data.split_sessions })
     .done(function() { location.reload() } )
     .fail( function(a,b,c) { alert('Splitting Ticket Failed') } )
  },

  edit_pass_recipient: function(e,m) {
    custy_selector.show_modal(m.pass.customer.id, function(custy_id) {
      $.post('/models/events/passes/' + m.pass.id + '/transfer', { customer_id: custy_id } );
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
   .success( function(tic) { data['ticket'] = tic; $('#json-viewer').jsonViewer(data['ticket']); } )
   .fail   ( function()    { alert("failed to get ticket data"); } )
}