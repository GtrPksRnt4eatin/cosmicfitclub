ctrl = {

  punch_in: function(e,m) {
    $.post( '/models/hourly/punch_in',  { hourly_task_id: 1 } )
     .done( get_punches )
     .fail( show_error  )
  },

  punch_out: function(e,m) {
    $.post( '/models/hourly/punch_out' )
     .done( get_punches  )
     .fail( show_error   )
  } 

}

$(document).ready(function() {
  
  userview = new UserView( id('userview_container'));

  include_rivets_dates();

  rivets.formatters.task_name = function(val)          { task = data['hourly_tasks'].find( function(x) { return x.id == val } ); return ( task ? task.name : "" ) }
  rivets.formatters.elapsed_time = function(val,start) { var dur = moment.duration(val.diff(start)); return(dur.hours() + ' H, ' + dur.minutes() + ' M, ' + dur.seconds() + ' S'); }
  rivets.formatters.punch_details = function(punch)      {
    var dur = moment(punch.starttime).diff(moment(punch.endtime) ) 
    var hrs = dur.hours();
    var min = dur.minutes();
    var hrs = hrs + (Math.round(40/15)*15)/60;
    return( hrs + ' hours @ $10ea = $' + hrs*10 + '.00' );
  }
  rivets.bind( document.body, { data: data, ctrl: ctrl } );

  get_punches();

  setInterval(function(){ data['current_time'] = moment(); }, 1000 );

});

function get_punches() {
  $.get('/models/hourly/my_punches', on_punches);
}

function on_punches(punches) {
  data['punches'] = punches;
}

function show_error(xhr) {
  alert("Request Failed: " + xhr.responseText); 
}