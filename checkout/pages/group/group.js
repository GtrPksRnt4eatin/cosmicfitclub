data = {
  reservation: {}
}

$(document).ready( function() {
  include_rivets_dates();
  include_rivets_money();

  popupmenu = new PopupMenu( id('popupmenu_container') );
  pay_form = new PaymentForm();

  pay_form.customer_facing();
  pay_form.ev_sub('show', popupmenu.show );
  pay_form.ev_sub('hide', popupmenu.hide );


  $.get('/models/groups/' + reservation_id)
   .then(function(val) {
     console.log(val);
     data.reservation = val;
   })

   rivets.bind( $('body'), { data: data });
});