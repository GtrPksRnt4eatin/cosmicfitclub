$(document).ready(function() {
  setInterval(function() {
    $.get('/door/status', function(resp) {
      $('button').css('display', 'inline-block');
      $('#loading').css('display', 'none');
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
    }, 'json');
  }, 2000);
 
  $('#up').on('click', function(e) {
    $.post('/door/open');
    cancelEvent(e);
  });

  $('#down').on('click', function(e) {
    $.post('/door/close');
    cancelEvent(e);
  });

  $('#momentary').on('click', function(e) {
    $.post('/door/momentary');
    cancelEvent(e);
  });

});
