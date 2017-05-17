$(document).ready(function() {
  $('#up').on('mousedown touchdown', function(e) {
    $.post('/door/up');
  });

  $('#down').on('mousedown touchdown', function(e) {
    $.post('/door/down', 'val=1' );
  });

  $('#down').on('mouseup touchup mouseout', function(e) {
  	$.post('/door/down', 'val=0' );
  });

  $('#stop').on('mousedown touchdown', function(e) {
    $.post('/door/stop');
  });

});