data = {
  fb_events: [],
  eb_events: []
}

ctrl = {

}

$(document).ready(function() {

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

  get_fb_events();
  get_eb_events();

});

function get_fb_events() {
  $.get('/integrations/facebook/event_list', function(val) { data.fb_events = val; } );
}

function get_eb_events() {
  $.get('/integrations/eventbrite/event_list', function(val) { data.eb_events = val; } );
}