var data = {
  events: []
}

$(document).ready(function() {

  rivets.bind(document.body, { data: data } );
  rivets.formatters.dayofwk  = function(val) { return moment(val).format('ddd') };
  rivets.formatters.date     = function(val) { return moment(val).format('MMM Do') };
  rivets.formatters.time     = function(val) { return moment(val).format('h:mm a') };
  rivets.formatters.fulldate = function(val) { return moment(val).format('ddd MMM Do hh:mm a') };

  $('#logo').on('click', function(e) {
    window.location.href = '/';
  });

  $('#menu li').on('click', function(e) {
    window.location.href = e.target.getAttribute('href');
  });

  $.get('/models/events', function(events) {
    data.events = JSON.parse(events);
  });

});