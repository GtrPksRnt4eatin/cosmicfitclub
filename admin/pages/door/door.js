$(document).ready(function() {
  setInterval(function() {
    $.get('http://192.168.1.16/cm?cmnd=Power', function(resp) {
       console.log(resp);
    });
  }, 500);
 
  $('#up').on('click', function(e) {
    $.post('http://192.168.1.16/cm?cmnd=Power%20On');
    cancelEvent(e);
  });

  $('#down').on('click', function(e) {
    $.post('http://192.168.1.16/cm?cmnd=Power%20Off');
    cancelEvent(e);
  });  

});
