data = {
  punches: []
}

$(document).ready(function() {
  
  userview = new UserView( id('userview_container'));

  $('#punch_in').click( function() {
    $.post("/models/hourly/punch_in", { customer_id: userview.user.id, hourly_task_id: 1 } )
     .done(get_punches)
     .fail( function() { console.log("failed to punch in") } );
  });

  $('#punch_out').click( function() {

  });

  rivets.bind( document.body, { data: data } );

});

function get_punches() {
  $.get('/models/hourly/punches', { "customer_id": userview.user.id }, on_punches);
}

function on_punches(punches) {
  data['punches'] = punches;
}