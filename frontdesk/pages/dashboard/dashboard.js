data = {
  bus_times: {},
  current_time: ""
}

$(document).ready( function() { 
  updateClock();
  getBusTimes();
  setInterval(updateClock, 1000  );
  setInterval(getBusTimes, 10000 );
  var binding = rivets.bind( $('body'), { data: data } );
});

function updateClock() {
  data.current_time = new Date().toLocaleString('en-US', { hour: 'numeric', minute: 'numeric', hour12: true });
}

function getBusTimes() {
  $.get('/frontdesk/bus_times', function(resp) { 
    data.bus_times = resp;
  }, 'json')
}