var checkout;

data = {
  id: 0,
  email: null,
  full_name: null
}

ctrl = {
  check_email: function(e,m) { 
    $.get('/auth/email_search', { email: e.target.value }, function(val) {
      data.id = val ? val.id : 0;
      data.email = val ? val.email : data.email;
      data.full_name = val ? val.full_name : '';
    } );
  }
}

$(document).ready(function(){

	//include_rivets_dates();
    include_rivets_money();
    var binding = rivets.bind( $('body'), { ctrl: ctrl, data: data } );

    payment_form     = new PaymentForm();
    popupmenu        = new PopupMenu( id('popupmenu_container') );
    userview         = new UserView( id('userview_container') );

    payment_form.customer_facing();
    payment_form.clear_customer();
    payment_form.ev_sub('show', popupmenu.show );
    payment_form.ev_sub('hide', popupmenu.hide );
    popupmenu.ev_sub('close', payment_form.stop_listen_cardswipe);

    userview.ev_sub('on_user', on_user );

    $('#checkout_button').click(function() { payment_form.checkout( 1, 10000, "Ten Class Pack (discounted)", null, on_payment) });
                                                                    // customer_id, price, reason, metadata, callback
})

function on_user(user) {
  if( empty(user) ) { payment_form.clear_customer();      }
  else              { payment_form.get_customer(user.id); }
  data.full_name = empty(user) ? '' : user.name;
  data.email = empty(user) ? '' : user.email;
}

function on_payment(payment) {
  var x=5;
}