$(document).ready(function() {
  $('#up').on('mousedown', function(e) {
    $.post('/door/up');
  });

  $('#down').on('mousedown', function(e) {
    $.post('/door/down', 'val=1' );
  });

  $('#down').on('mouseup mouseout', function(e) {
  	$.post('/door/down', 'val=0' );
  });

  $('#stop').on('mousedown', function(e) {
    $.post('/door/stop');
  });

});