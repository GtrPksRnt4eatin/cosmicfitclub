var checkout;

$(document).ready(function(){

	//include_rivets_dates();
    include_rivets_money();
    //var binding = rivets.bind( $('body'), { data: data } );

    payment_form     = new PaymentForm();
    popupmenu        = new PopupMenu( id('popupmenu_container') );
    //userview         = new UserView();

    payment_form.customer_facing();
    payment_form.ev_sub('show', popupmenu.show );
    payment_form.ev_sub('hide', popupmenu.hide );
    popupmenu.ev_sub('close', payment_form.stop_listen_cardswipe);

    //userview.ev_sub('on_user', function(user) { data.username = ( user == null ? '' : user.name ); } );

    $('#checkout_button').click(function() { payment_form.checkout(1, 10000, "Ten Class Pack (discounted)", null, on_payment) });
                                                                   // customer_id, price, reason, metadata, callback
})

function on_payment(payment) {
  var x=5;
}