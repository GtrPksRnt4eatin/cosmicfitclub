$(document).ready(function() {
  $('#up').on('mousedown touchstart', function(e) {
  	cancelEvent(e);
    $.post('/door/up');
  });

  $('#down').on('mousedown touchstart', function(e) {
  	cancelEvent(e);
    $.post('/door/down', 'val=1' );
  });

  $('#down').on('mouseup touchend mouseout', function(e) {
  	cancelEvent(e);
  	$.post('/door/down', 'val=0' );
  });

  $('#stop').on('mousedown touchend', function(e) {
  	cancelEvent(e);
    $.post('/door/stop');
  });

});