ctrl = {}

$(document).ready( function() {

    setup_bindings();

    reservation_form = new ReservationForm(id('reservation_form_container'));

    $('#customers').chosen();
    $('#customers').on('change', reservation_form.load_customer );

});

function setup_bindings() {

  include_rivets_dates();
  var binding = rivets.bind( $('body'), { data: data, ctrl: ctrl } );

}