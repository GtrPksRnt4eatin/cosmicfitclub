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
  }
}

$(document).ready(function() {
  
  custy_selector = new CustySelector();

  include_rivets_select();
  include_rivets_dates();
  initialize_rivets() 
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