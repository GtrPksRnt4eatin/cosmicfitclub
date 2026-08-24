$(document).ready(function() {

  userview = new UserView( id('userview_container'));

  var payment_sources = new PaymentSources(
    id('payment_sources_container'),
    { customer: { id: data.customer.id, email: data.customer.email } }
  );
  payment_sources.refresh();

  $('.cancel_res').on('click', function() {
  	var id = parseInt(this.getAttribute('data-id'));
  	if( !confirm("Really Cancel Your Reservation?") ) return;
    $.del('/models/classdefs/reservations/' + id)
     .success( function() { location.reload(); } );
  } );

  rivets.bind({ data: data })

});