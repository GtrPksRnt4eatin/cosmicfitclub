ctrl = {
  assign_recipient: function(e,m) {
    $.post('/models/events/tickets/' + data.ticket.id + '/assign_recipient', { recipient_id: data.recipient })
     .done(function() { location.reload() } )
     .fail( alert('Assigning Recipient Failed') )
  },

  split_ticket: function(e,m) {
    $.post('/models/events/tickets/' + data.ticket.id + '/assign_recipient', { recipient_id: data.recipient })
     .done(function() { location.reload() } )
     .fail( alert('Splitting Ticket Failed') )
  }
}

$(document).ready(function() {
  include_rivets_select();
  initialize_rivets() 
})

function initialize_rivets() {
  rivets.bind( document.body, { data: data, ctrl: ctrl } );
}