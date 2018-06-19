$(document).ready(function() {
  $('#up').on('click', function(e) {
    $.post('/door/up');
    cancelEvent(e);
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