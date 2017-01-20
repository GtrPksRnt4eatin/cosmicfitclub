data = {
  classes: []
}

$(document).ready(function() {

  get_saved_classes();
  rivets.bind( $('body'), { data: data } );

});

function get_saved_classes() {
  $.get('/models/classdefs', function(classes) {
    data.classes = JSON.parse(classes);
  })
} 