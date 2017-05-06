data = {
  day: ""
}

$(document).ready(function() {

  schedule = new Schedule( id('schedule_container') );
  schedule.ev_sub('day_of_week', function(day) { data['day'] = day; });
  rivets.formatters.equals = function(val, match) { return val == match; }
  rivets.bind( $('body'), { data: data } );
  schedule.set_formatted_date();

});