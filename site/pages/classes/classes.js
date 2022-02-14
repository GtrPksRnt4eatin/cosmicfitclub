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

  rivets.bind( document.body, { data: data, ctrl: ctrl } );

  rivets.formatters.thumb = function (id)  { return '/models/classdefs/' + id + '/thumb'}
  rivets.formatters.join  = function (val) { return val.map( function(val) { return val.name; } ).join(' & '); }

});

function get_saved_classes() {
  $.get('/models/classdefs/ranked_list', function(classes) {
    data.classes = classes;
  })
} 