data = {
  bus_times: {},
  current_time: ""
}

ctrl = {
  color_change(e,m) {
    let x=5;
  }
}

$(document).ready( function() { 
  updateClock();
  getBusTimes();
  var view = rivets.bind( $('body'), { data: data, ctrl: ctrl } );
  calendar = get_element(view, 'loft-calendar');
  setInterval(updateClock,     1000);
  setInterval(getBusTimes,    20000);
  setInterval(updateCalendar, 120000);
});

function updateClock() {
  data.current_time = new Date().toLocaleString('en-US', { hour: 'numeric', minute: 'numeric', hour12: true });
}

function updateCalendar() {
  calendar.full_refresh();
}

function getBusTimes() {
  $.get('/frontdesk/bus_times', function(resp) { 
    data.bus_times = resp;
  }, 'json')
}