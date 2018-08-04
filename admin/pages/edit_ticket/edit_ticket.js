ctrl = {
  assign_recipient: function(e,m) {
    
  },

  split_ticket: function(e,m) {
    
  }
}

$(document).ready(function() { 
  initialize_rivets() 
}

function initialize_rivets() {
  rivets.bind( document.body, { data: data, ctrl: ctrl } );
}