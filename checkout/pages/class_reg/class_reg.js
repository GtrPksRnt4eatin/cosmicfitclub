$(document).ready( function() {

    include_rivets_dates();
    include_rivets_money();
    var binding = rivets.bind( $('body'), { data: data } );

    payment_form     = new PaymentForm();
    popupmenu        = new PopupMenu( id('popupmenu_container') );
    reservation_form = new ReservationForm( id('reservation_form_container') );
    userview         = new UserView();

    reservation_form.stack();
    reservation_form.set_occurrence(data['occurrence']);
    reservation_form.ev_sub('reservation_made', function() { $(document.body).addClass('done') } );
    reservation_form.ev_sub('paynow', function(args) { payment_form.checkout(args[0], args[1], null, args[3], args[4]) });

    payment_form.customer_facing();
    payment_form.ev_sub('show', popupmenu.show );
    payment_form.ev_sub('hide', popupmenu.hide );
    popupmenu.ev_sub('close', payment_form.stop_listen_cardswipe);

    userview.ev_sub('on_user', function(user) { data.username = ( user == null ? '' : user.name ); } );
    userview.ev_sub('on_user', function(user) { reservation_form.load_customer(user.id); } );

} );