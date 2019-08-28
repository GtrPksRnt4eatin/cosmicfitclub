$(document).ready(function() {

  userview = new UserView( id('userview_container'));

  $('.cancel_res').on('click', function() {
  	var id = parseInt(this.getAttribute('data-id'));
  	if( !confirm("Really Cancel Your Reservation?") ) return;
    $.del('/models/classdefs/reservations/' + id)
     .success( function() { location.reload(); } );
  } );

  rivets.bind({ data: data })

});