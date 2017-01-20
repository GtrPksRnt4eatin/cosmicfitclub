var data = {
  events: []
}

$(document).ready(function() {

  rivets.bind(document.body, { data: data } );
  rivets.formatters.dayofmo  = function(val) { return moment(val).format('Do') };
  rivets.formatters.dayofwk  = function(val) { return moment(val).format('ddd') };
  rivets.formatters.date     = function(val) { return moment(val).format('MMM Do') };
  rivets.formatters.time     = function(val) { return moment(val).format('h:mm a') };
  rivets.formatters.fulldate = function(val) { return moment(val).format('ddd MMM Do hh:mm a') };

  $.get('/models/events', function(events) {
    data.events = JSON.parse(events);
  });

});