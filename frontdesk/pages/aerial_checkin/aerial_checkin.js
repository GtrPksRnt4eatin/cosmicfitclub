// ============================================================
//  Aerial Point Kiosk Check-In  —  rivets-bound
// ============================================================

var payment_form;
var popupmenu;

var data = {
  prev: [], curr: [], next: [],
  modal: {
    open:         false,
    success:      false,
    success_name: '',
    busy:         false,
    res:          null,
    slot:         null,
    customer:     null,
    lookup_email: '',
    passes_needed: 0,
    amount_cents:  0
  }
};

var ctrl = {
  open_modal:    open_modal,
  close_modal:   close_modal,
  pay_passes:    pay_passes,
  pay_card:      pay_card,
  lookup_passes: lookup_passes
};

// ---- Init --------------------------------------------------

$(document).ready(function () {
  setup_bindings();

  payment_form = new PaymentForm();
  popupmenu    = new PopupMenu(id('popupmenu_container'));

  payment_form.customer_facing();
  payment_form.ev_sub('show', popupmenu.show);
  payment_form.ev_sub('hide', function (args) {
    popupmenu.hide(args);
    if (!data.modal._completing) { data.modal.busy = false; }
  });

  tick_clock();
  setInterval(tick_clock, 1000);

  load_reservations();
  setInterval(load_reservations, 60000);
});

function setup_bindings() {
  rivets.formatters.edit_href    = function (res)   { return res ? '/frontdesk/point_reservation/' + res.id : '#'; };
  rivets.formatters.res_time     = function (res)   { if (!res) return ''; return moment(res.start_time).format('h:mm') + ' – ' + moment(res.end_time).format('h:mm A'); };
  rivets.formatters.res_dur      = function (res)   {
    if (!res) return '';
    var h = Math.round((new Date(res.end_time) - new Date(res.start_time)) / 3600000);
    return h + ' hr' + (h !== 1 ? 's' : '');
  };
  rivets.formatters.slot_name    = function (slot)  { return slot ? (slot.customer_string || 'Guest') : ''; };
  rivets.formatters.modal_time   = function (modal) {
    if (!modal.res) return '';
    var dur = Math.round((new Date(modal.res.end_time) - new Date(modal.res.start_time)) / 3600000);
    return moment(modal.res.start_time).format('h:mm A') + ' – ' + moment(modal.res.end_time).format('h:mm A') +
           '  (' + dur + ' hr' + (dur !== 1 ? 's' : '') + ')';
  };
  rivets.formatters.dollars      = function (cents) { return (cents / 100).toFixed(2); };
  rivets.formatters.passes_label = function (n)     { return parseFloat(n).toFixed(1); };
  rivets.formatters.has_passes   = function (modal) { return modal.customer && modal.customer.num_passes >= modal.passes_needed; };
  rivets.formatters.lacks_passes = function (modal) { return modal.customer && modal.customer.num_passes <  modal.passes_needed; };

  rivets.bind($('body'), { data: data, ctrl: ctrl });
}

// ---- Clock -------------------------------------------------

function tick_clock() {
  var now = moment();
  id('clock').textContent = now.format('h:mm A') + '  ' + now.format('ddd, MMM D');
}

// ---- Data --------------------------------------------------

function load_reservations() {
  $.get('/models/groups/aerial_window', function (resp) {
    var now = new Date();
    var prev = [], curr = [], next = [];

    resp.forEach(function (res) {
      var start = new Date(res.start_time);
      var end   = new Date(res.end_time);
      if      (end   <= now) { prev.push(res); }
      else if (start <= now) { curr.push(res); }
      else                   { next.push(res); }
    });

    // Replace array references — rivets observes the keypath and re-renders
    data.prev = prev.slice(-1);
    data.curr = curr;
    data.next = next.slice(0, 3);

    // Re-tag back-references after array swap
    [data.prev, data.curr, data.next].forEach(function (list) {
      list.forEach(function (res) {
        (res.slots || []).forEach(function (slot) { slot._res = res; });
      });
    });
  }, 'json');
}

// ---- Modal -------------------------------------------------

function open_modal(e, m) {
  var slot = m.slot;
  var res  = slot._res;

  var dur          = Math.round((new Date(res.end_time) - new Date(res.start_time)) / 3600000);
  var passes_needed = dur;
  var amount_cents  = passes_needed * 1200;

  data.modal.res          = res;
  data.modal.slot         = slot;
  data.modal.customer     = null;
  data.modal.lookup_email = '';
  data.modal.passes_needed = passes_needed;
  data.modal.amount_cents  = amount_cents;
  data.modal.busy         = false;
  data.modal.success      = false;
  data.modal.success_name = '';
  data.modal.open         = true;

  // Auto-load passes if customer is already known on the slot
  if (slot.customer_id) {
    $.get('/models/customers/' + slot.customer_id + '/class_passes', function (passes) {
      data.modal.customer = { id: slot.customer_id, name: slot.customer_string, num_passes: passes };
    }, 'json');
  }
}

function close_modal() {
  data.modal.open    = false;
  data.modal.success = false;
  data.modal.busy    = false;
}

// ---- Pass lookup -------------------------------------------

function lookup_passes() {
  var email = (data.modal.lookup_email || '').trim();
  if (!email) return;

  $.get('/models/groups/customer_lookup?email=' + encodeURIComponent(email), function (custy) {
    data.modal.customer = custy;
  }, 'json').fail(function (e) {
    alert(e.status === 404 ? 'No account found. Please pay by card.' : 'Error looking up account.');
  });
}

// ---- Payments ----------------------------------------------

function pay_passes() {
  if (data.modal.busy) return;
  var modal = data.modal;
  if (!modal.customer) return;

  modal.busy = true;
  modal._completing = true;

  $.post('/models/groups/slots/' + modal.slot.id + '/checkin', {
    payment_type: 'passes',
    customer_id:  modal.customer.id
  }, function (updated_slot) {
    modal._completing = false;
    show_success(updated_slot.customer_string || 'Guest');
  }, 'json').fail(function (e) {
    modal.busy = false;
    modal._completing = false;
    alert('Check-in failed: ' + (e.responseText || 'Unknown error'));
  });
}

function pay_card() {
  if (data.modal.busy) return;
  var modal  = data.modal;
  var reason = 'Aerial Point: ' + moment(modal.res.start_time).format('MMM D h:mm A');

  modal.busy = true;
  modal._completing = true;

  payment_form.checkout(
    modal.customer ? modal.customer.id : null,
    modal.amount_cents,
    reason,
    { type: 'rental' },
    function (payment_id) {
      $.post('/models/groups/slots/' + modal.slot.id + '/checkin', {
        payment_id: payment_id
      }, function (updated_slot) {
        modal._completing = false;
        show_success(updated_slot.customer_string || 'Guest');
      }, 'json').fail(function (e) {
        modal.busy = false;
        modal._completing = false;
        alert('Check-in failed after payment: ' + (e.responseText || 'Unknown error'));
      });
    }
  );
}

// ---- Success -----------------------------------------------

function show_success(name) {
  data.modal.success      = true;
  data.modal.success_name = name;
  data.modal.busy         = false;
  load_reservations();
  setTimeout(close_modal, 5000);
}
