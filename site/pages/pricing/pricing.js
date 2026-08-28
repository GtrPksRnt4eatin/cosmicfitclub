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
  
  $('.buy-button').on('click', function(e) {
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
