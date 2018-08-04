ctrl = {
  assign_recipient: function(e,m) {
    $.post('/models/events/tickets/' + data.ticket.id + '/assign_recipient', { recipient_id: data.})
  },

  split_ticket: function(e,m) {
    
  }
}

$(document).ready(function() { 
  initialize_rivets() 
})

function initialize_rivets() {
  rivets.bind( document.body, { data: data, ctrl: ctrl } );
}