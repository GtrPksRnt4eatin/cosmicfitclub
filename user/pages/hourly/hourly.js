$(document).ready(function() {
  
  userview = new UserView( id('userview_container'));

  $('#punch_in').click( function() {
    $.post("/models/hourly/punch_in", { customer_id: userview.user.id, hourly_task_id: 1 } )
     .done( get_punches )
     .fail( function(request) { alert("failed to punch in: " + request.responseText ); } );
  });

  $('#punch_out').click( function() {

  });

  include_rivets_dates();

  rivets.formatters.task_name = function(val)          { task = data['hourly_tasks'].find( function(x) { return x.id == val } ); return ( task ? task.name : "" ) }
  rivets.formatters.elapsed_time = function(val,start) { var dur = moment.duration(val.diff(start)); return(dur.hours() + ':' + dur.minutes()); }
  rivets.bind( document.body, { data: data } );

  get_punches();

  setInterval(function(){ data['current_time'] = moment(); }, 1000 );

});

function get_punches() {
  $.get('/models/hourly/punches?customer_id=' + userview.user.id, on_punches);
}

function on_punches(punches) {
  data['punches'] = punches;
}