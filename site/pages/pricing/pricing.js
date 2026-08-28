var payment_form;
var popupmenu;
var userview;

var PASS_PRICE      = 1200;   // cents per pass (1–19)
var DEAL_PRICE      = 20000;  // cents for 20 passes
var DEAL_QUANTITY   = 20;

$(document).ready(function() {

  userview    = new UserView(id('userview_container'));
  popupmenu   = new PopupMenu(id('popupmenu_container'));
  payment_form = new PaymentForm();

  payment_form.customer_facing();
  payment_form.ev_sub('show', popupmenu.show);
  payment_form.ev_sub('hide', popupmenu.hide);

  // ── Quantity picker ────────────────────────────────────────────────────────
  function updateDisplay() {
    var qty   = parseInt($('#pass-qty').val()) || 1;
    qty       = Math.max(1, Math.min(DEAL_QUANTITY, qty));
    $('#pass-qty').val(qty);

    var isDeal  = qty === DEAL_QUANTITY;
    var cents   = isDeal ? DEAL_PRICE : qty * PASS_PRICE;
    var dollars = '$' + (cents / 100).toFixed(2);

    $('#qty-display').text(qty);
    $('#plural-s').text(qty === 1 ? '' : 'es');
    $('#price-display').text(dollars);
    $('#price-note').text(isDeal ? 'You save $40.00 vs. buying individually!' : '$12.00 each');
    $('#deal-badge').toggle(isDeal);
    $('#buy-passes-btn').text('Buy ' + qty + ' Pass' + (qty === 1 ? '' : 'es') + ' for ' + dollars);
  }

  $('#pass-qty').on('input change', updateDisplay);
  $('#qty-minus').on('click', function() {
    var v = parseInt($('#pass-qty').val()) || 1;
    $('#pass-qty').val(Math.max(1, v - 1));
    updateDisplay();
  });
  $('#qty-plus').on('click', function() {
    var v = parseInt($('#pass-qty').val()) || 1;
    $('#pass-qty').val(Math.min(DEAL_QUANTITY, v + 1));
    updateDisplay();
  });
  updateDisplay();

  // ── Buy button ─────────────────────────────────────────────────────────────
  $('#buy-passes-btn').on('click', function(e) {
    e.preventDefault();
    if (!userview.logged_in) { userview.onboard(); return; }

    var qty     = parseInt($('#pass-qty').val()) || 1;
    qty         = Math.max(1, Math.min(DEAL_QUANTITY, qty));
    var isDeal  = qty === DEAL_QUANTITY;
    var cents   = isDeal ? DEAL_PRICE : qty * PASS_PRICE;
    var label   = qty + ' Pass' + (qty === 1 ? '' : 'es') + (isDeal ? ' (Deal)' : '');

    payment_form.checkout(userview.id, cents, label, null, function(payment_id) {
      completePurchase(qty, payment_id);
    });
  });

});

function completePurchase(num_passes, payment_id) {
  $.post('/checkout/passes/buy', {
    customer_id: userview.id,
    num_passes:  num_passes,
    payment_id:  payment_id
  }, 'json')
  .done(function() { window.location = '/checkout/complete'; })
  .fail(function(e) { alert('There was an error completing your purchase. Please contact support.'); console.error(e); });
}
