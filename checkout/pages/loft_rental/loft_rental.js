data = {
  rental: {
    starttime: '',
    endtime: '',
    activity: '',
    note: ''
  }
};

$(document).ready( function() {

    include_rivets_dates();
    var binding = rivets.bind( $('body'), { data: data } );arguments

});