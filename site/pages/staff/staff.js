data = {
  items: []
}

$(document).ready(function() {

  rivets.bind( $('body'), { data: data });

  get_saved_items();

  $('.content').on('click', '.more', function(e) {
    $(e.target).parents().eq(1).find('.bio').toggle();
  });

});

function get_saved_items() {
  $.get( '/models/staff/public_list', function(items) { data.items = items; })
} 