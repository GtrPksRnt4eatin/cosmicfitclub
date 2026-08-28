var payment_form;
var popupmenu;
var userview;

$(document).ready(function() {

  userview = new UserView(id('userview_container'));
  popupmenu = new PopupMenu(id('popupmenu_container'));
  payment_form = new PaymentForm();
  
  payment_form.customer_facing();
  payment_form.ev_sub('show', popupmenu.show);
  payment_form.ev_sub('hide', popupmenu.hide);
  
  // quantity display for single pass row
  $('#pass-qty').on('input', function() {
    var qty = Math.max(1, Math.min(19, parseInt($(this).val()) || 1));
    $(this).val(qty);
    $('#pass-total').text('$' + (qty * 12).toFixed(2));
  });

  $('#buy-passes-btn').on('click', function(e) {
    e.preventDefault();
    if (!userview.logged_in) { userview.onboard(); return; }
    var qty   = Math.max(1, Math.min(19, parseInt($('#pass-qty').val()) || 1));
    var cents = qty * 1200;
    var label = qty + ' Pass' + (qty === 1 ? '' : 'es');
    payment_form.checkout(userview.id, cents, label, null, function(payment_id) {
      $.post('/checkout/passes/buy', { customer_id: userview.id, num_passes: qty, payment_id: payment_id })
       .done(function() { window.location = '/checkout/complete'; })
       .fail(function(e) { alert('There was an error completing your purchase. Please contact support.'); console.error(e); });
    });
  });

  $('.buy-button[data-type]').on('click', function(e) {
    e.preventDefault();
    if (!userview.logged_in) { userview.onboard(); return; }
    
    const button = $(this);
    const type = button.data('type');
    const id = button.data('id');
    const name = button.data('name');
    const amount = button.data('amount');
    
    payment_form.checkout(userview.id, amount, name, { type: type, id: id }, 
      function(payment_id) { completePurchase(type, id, payment_id); }
    );
  });
  
});

function completePurchase(type, id, payment_id) {
  let endpoint;
  let data = { 
    payment_id: payment_id,
    customer_id: userview.id
  };
  
  if      (type === 'pack') { endpoint = '/checkout/pack/buy';    data.pack_id = id; } 
  else if (type === 'plan') { endpoint = '/checkout/plan/charge'; data.plan_id = id; }
  
  $.post(endpoint, data, 'json')
   .done(function() { window.location = '/checkout/complete'; })
   .fail(function(e) { alert('There was an error completing your purchase. Please contact support.'); console.error(e); });
}
