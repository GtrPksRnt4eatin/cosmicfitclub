data = {
  reservation: {}
}

ctrl = {
  full_delete: function(e,m) {
    $.del( `/models/groups/${data.reservation_id}` )
     .done( function() { History.back(); } )
     .fail( function() { alert('Failed to delete'); } )
  },
  checkout_card: function(e,m) {
    let start = rivets.formatters.classtime(data.reservation.start_time);
    let desc = `Point Rental for ${start}`;
    let price = parseInt($('#payval').val()) * 100;
    pay_form.checkout(userview.id, price, desc, null, function(payment_id) {
      var payload = {
        customer_id: userview.id,
        reservation_id: data.reservation.id,
        payment_id: payment_id 
      }

      $.post('apply_payment', payload)
       .done( on_successful_charge )
       .fail( on_failed_charge     );
    })
  },
  checkout_passes: function(e,m) {
    let start = rivets.formatters.classtime(data.reservation.start_time);
    let desc = `Point Rental for ${start}`;
    let passes = parseInt($('#passval').val());

    var payload = {
      customer_id: userview.id,
      reservation_id: data.reservation.id,
      passes: passes 
    }
    
    $.post('apply_passes', payload)
     .done( on_successful_charge )
     .fail( on_failed_charge     );
  }
}

function on_successful_charge(e) { 
  window.location.href = '/checkout/complete'; 
}

function on_failed_charge(e) {
  switch (e.status) {
    case 400: 
      alert('There was an error processing the payment. Your Card Has not been charged.'); 
      break;
    case 409: 
      alert('Your Card Has not Been Charged. You already have a Membership, Sign in to Modify it.'); 
      window.location.href = '/login'; 
      break;
    case 500: 
      alert('An Error Occurred!'); 
      break;
    default: 
      alert('huh???'); 
      break;
  }
} 

$(document).ready( function() {
  include_rivets_dates();
  include_rivets_money();

  userview  = new UserView( id('userview_container') );
  popupmenu = new PopupMenu( id('popupmenu_container') );
  
  custy_selector = new CustySelector();
  custy_selector.ev_sub('show'       , popupmenu.show );
  custy_selector.ev_sub('close_modal', popupmenu.hide );
  
  pay_form  = new PaymentForm();
  pay_form.customer_facing();
  pay_form.ev_sub('show', popupmenu.show );
  pay_form.ev_sub('hide', popupmenu.hide );

  $.get('/models/groups/' + reservation_id)
   .then(function(val) {
     console.log(val);
     data.reservation = val;
   })

   view = rivets.bind( $('body'), { data: data, ctrl: ctrl });
   group_reservation = get_element(view,'group-reservation');

   group_reservation.ev_sub('choose_custy', custy_selector.show_modal );

});

