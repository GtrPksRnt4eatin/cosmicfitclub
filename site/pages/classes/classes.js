data = {
  classes: []
}

ctrl = {
  class_detail: function(e,m) {
  	window.location.href = 'class/' + m.class.id;
  }
}

$(document).ready(function() {

  get_saved_classes();

  include_rivets_rrule();
  include_rivets_dates();

  rivets.bind( $('body'), { data: data, ctrl: ctrl } );

  rivets.formatters.thumb = function (id) { return '/models/classdefs/' + id + '/thumb'}

});

function get_saved_classes() {
  $.get('/models/classdefs', function(classes) {
    data.classes = JSON.parse(classes).filter(function(x) { return x.schedules.length > 0; } );
  })
} 