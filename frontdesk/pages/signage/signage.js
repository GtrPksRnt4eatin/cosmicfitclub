$(document).ready( function() { 
    view = rivets.bind( $('body'), { data: data, ctrl: ctrl } );
    bus_times = get_element(view, 'bus-times');
  });