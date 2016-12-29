data = {
  classes: []
}

$(document).ready(function() {

  $('#logo').on(    'click', function(e) { window.location.href = '/'; }                           );
  $('#menu li').on( 'click', function(e) { window.location.href = e.target.getAttribute('href'); } );

  get_saved_classes();
  rivets.bind( $('body'), { data: data } );

});

function get_saved_classes() {
  $.get('/models/classdefs', function(classes) {
    data.classes = JSON.parse(classes);
  })
} 