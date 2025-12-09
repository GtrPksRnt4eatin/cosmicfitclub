var payment_form;
var popupmenu;
var userview;

$(document).ready(function() {
  
  // Initialize components
  userview = new UserView(id('userview_container'));
  popupmenu = new PopupMenu(id('popupmenu_container'));
  payment_form = new PaymentForm();
  
  // Subscribe to events
  payment_form.ev_sub('show', popupmenu.show);
  payment_form.ev_sub('hide', popupmenu.hide);
  
  // Handle buy button clicks
  $('.buy-button').on('click', function(e) {
    e.preventDefault();
    
    // Check if user is logged in
    if (!userview.logged_in) {
      userview.onboard();
      return;
    }
    
    const button = $(this);
    const type = button.data('type');
    const id = button.data('id');
    const name = button.data('name');
    const amount = button.data('amount');
    
    // Open payment form
    payment_form.checkout(
      userview.id,
      amount,
      name,
      { type: type, id: id },
      function(payment_id) {
        // After successful payment, complete the purchase
        completePurchase(type, id, payment_id);
      }
    );
  });
  
});

function completePurchase(type, id, payment_id) {
  let endpoint;
  let data = { payment_id: payment_id };
  
  if (type === 'pack') {
    endpoint = '/checkout/pack/buy';
    data.pack_id = id;
  } else if (type === 'plan') {
    endpoint = '/checkout/plan/charge';
    data.plan_id = id;
  }
  
  $.post(endpoint, data, 'json')
    .done(function() {
      window.location = '/checkout/complete';
    })
    .fail(function(e) {
      alert('There was an error completing your purchase. Please contact support.');
      console.error(e);
    });
}
