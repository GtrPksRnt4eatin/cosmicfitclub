$(document).ready(function() {
  setInterval(function() {
    $.get('/door/status', function(resp) {
       switch(resp?.POWER) {
         case 'ON': 
           $('#up').css('background', 'rgba(0,255,0,0.2)');
           $('#down').css('background', 'rgba(255,255,255,0.2)');
           break;
         case 'OFF':
           $('#down').css('background', 'rgba(255,0,0,0.2)');
           $('#up').css('background', 'rgba(255,255,255,0.2)');
           break;          
       }
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
