ctrl = {
  cancel_res: function(e,m) {
  	if( !confirm("Really Cancel Your Reservation?") ) return;
    $.del('/models/classdefs/reservations/' + m.res.id)
     .success( function() { location.reload(); } );
  }
}

$(document).ready(function() {

  userview = new UserView( id('userview_container'));

  $('.cancel_res').on('click', function() {
  	var x = 5;
  } );

  rivets.bind({ data: data, ctrl: ctrl })

});