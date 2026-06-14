var payment_form;
var popupmenu;
var userview;

$(document).ready(function() {

  userview     = new UserView(id('userview_container'));
  popupmenu    = new PopupMenu(id('popupmenu_container'));
  payment_form = new PaymentForm();

  payment_form.customer_facing();
  payment_form.ev_sub('show', popupmenu.show);
  payment_form.ev_sub('hide', popupmenu.hide);

  $('.buy-button').on('click', function(e) {
    e.preventDefault();
    if (!userview.logged_in) { userview.onboard(); return; }

    payment_form.checkout(
      userview.id,
      PACKAGE['pass_price'] * PACKAGE['num_passes'],
      PACKAGE['name'],
      { type: 'pack', id: PACKAGE['id'] },
      function(payment_id) {
        $.post('/checkout/pack/buy', { payment_id: payment_id, customer_id: userview.id, pack_id: PACKAGE['id'] }, 'json')
         .done(function()  { window.location = '/checkout/complete'; })
         .fail(function(e) { alert('There was an error completing your purchase. Please contact support.'); console.error(e); });
      }
    );
  });

});
