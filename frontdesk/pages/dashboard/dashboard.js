data = {
  bus_times: {},
  current_time: ""
}

$(document).ready( function() { 
  
  setInterval(function() {
    $.get('/frontdesk/bus_times', function(resp) { 
      data.bus_times = resp;
    }, 'json')
  }, 3000 );

  setInterval(function() {
    var d = new Date();
    var s = d.getSeconds();
    var m = d.getMinutes();
    var h = d.getHours();
    data.current_time = h + ":" + m + ":" + s;
  }, 1000);

  var binding = rivets.bind( $('body'), { data: data } );

});