$(document).ready(function() {
  setInterval(function() {
    $.get('/door/status', function(resp) {
       console.log(resp);
       $('#status').innerHTML = resp;
    }, 'json');
  }, 1000);
 
  $('#up').on('click', function(e) {
    $.post('/door/open');
    cancelEvent(e);
  });

  $('#down').on('click', function(e) {
    $.post('/door/close');
    cancelEvent(e);
  });  

});
