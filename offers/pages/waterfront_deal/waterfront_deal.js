var checkout;

var email_regex = /(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])/

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
      id('fullname').disabled = val ? true : false;
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

    $('#checkout_button').click(function() { payment_form.checkout( data.id, 10000, "Ten Class Pack (discounted)", null, on_payment) });
                                                                    // customer_id, price, reason, metadata, callback
})

function on_user(user) {
  if( empty(user) ) { payment_form.clear_customer();      }
  else              { payment_form.get_customer(user.id); }
  data.id = empty(user) ? 0 : user.id;
  data.full_name = empty(user) ? '' : user.name;
  data.email = empty(user) ? '' : user.email;
  id('email').disabled = empty(user) ? false : true;
  id('fullname').disabled = empty(user) ? false : true;
}

function validate() {
  id('email').value 
}

function on_payment(payment) {
  var x=5;
}