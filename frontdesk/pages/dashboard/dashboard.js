data = {
  bus_times: {}
}

$(document).ready( function() { 
  
  setTimeout(function() {
    $.get('/frontdesk/bus_times', function(resp) { 
      data.bus_times = resp;
    })
  }, 3000 );

});